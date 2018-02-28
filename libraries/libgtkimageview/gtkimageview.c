/*  Copyright 2016 Timm Bäder
 *
 * GTK+ is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * GLib is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with GTK+; see the file COPYING.  If not,
 * see <http://www.gnu.org/licenses/>.
 */

/**
 * SECTION:gtkimageview
 * @Short_description: A widget for displaying content images to users
 * @Title: GtkImageView
 *
 * #GtkImageView is a widget intended to be used to display "content images"
 * to users. What we refer to as "content images" in the documentation could
 * be characterized as "images the user is deeply interested in". You should
 * use #GtkImageView whenever you want to actually present an image instead
 * of just using an icon.
 *
 * Contrary to #GtkImage, #GtkImageView does not just display an image with
 * a fixed size, but provides ways of rotating and scaling it, as well as
 * built-in gestures (via #GtkGestureRotate and #GtkGestureZoom) to rotate
 * and zoom the image.
 *
 *
 * # Scale factor handling
 *
 * All the functions intended to set the image of a #GtkImageView instance take a
 * "scale_factor" parameter (except for gtk_image_view_set_surface(), in which case
 * the scale factor of the surface is taken instead). This scale factor can be interpreted
 * the same as the #GtkWidget:scale-factor property of #GtkWidget, but for the given image.
 *
 */

#include "gtkimageview.h"
#include <gtk/gtk.h>
#include <math.h>

#define DEG_TO_RAD(x) (((x) / 360.0) * (2 * M_PI))
#define RAD_TO_DEG(x) (((x) / (2.0 * M_PI) * 360.0))

#define TRANSITION_DURATION (150.0 * 1000.0)
#define ANGLE_TRANSITION_MIN_DELTA (1.0)
#define SCALE_TRANSITION_MIN_DELTA (0.01)


#define _PARAM_READABLE G_PARAM_READABLE|G_PARAM_STATIC_NAME|G_PARAM_STATIC_NICK|G_PARAM_STATIC_BLURB
#define _PARAM_READWRITE G_PARAM_READWRITE|G_PARAM_STATIC_NAME|G_PARAM_STATIC_NICK|G_PARAM_STATIC_BLURB


typedef struct
{
  double hupper;
  double vupper;
  double hvalue;
  double vvalue;
  double angle;
  double scale;
} State;

struct _GtkImageViewPrivate
{
  double   scale;
  double   angle;
  int      scale_factor;

  gboolean fit_allocation      : 1;
  gboolean scale_set           : 1;
  gboolean snap_angle          : 1;
  gboolean rotatable           : 1;
  gboolean zoomable            : 1;
  gboolean in_rotate           : 1;
  gboolean in_zoom             : 1;
  gboolean size_valid          : 1;
  gboolean transitions_enabled : 1;
  gboolean in_angle_transition : 1;
  gboolean in_scale_transition : 1;

  GtkGesture *rotate_gesture;
  double      gesture_start_angle;
  double      visible_angle;

  GtkGesture *zoom_gesture;
  double      gesture_start_scale;
  double      visible_scale;

  /* Current anchor point, or -1/-1.
   * In widget coordinates. */
  double      anchor_x;
  double      anchor_y;


  GdkWindow *event_window;

  /* GtkScrollable stuff */
  GtkAdjustment       *hadjustment;
  GtkAdjustment       *vadjustment;
  GtkScrollablePolicy  hscroll_policy : 1;
  GtkScrollablePolicy  vscroll_policy : 1;

  gboolean                is_animation;
  GdkPixbufAnimation     *source_animation;
  GdkPixbufAnimationIter *source_animation_iter;
  cairo_surface_t        *image_surface;
  int                     animation_timeout;

  /* Transitions */
  double transition_start_angle;
  gint64 angle_transition_start;
  guint  angle_transition_id;

  double transition_start_scale;
  gint64 scale_transition_start;
  guint  scale_transition_id;

  /* We cache the bounding box size so we don't have to
   * recompute it at every draw() */
  double cached_width;
  double cached_height;
  double cached_scale;
};

enum
{
  PROP_SCALE = 1,
  PROP_SCALE_SET,
  PROP_ANGLE,
  PROP_ROTATABLE,
  PROP_ZOOMABLE,
  PROP_SNAP_ANGLE,
  PROP_FIT_ALLOCATION,
  PROP_TRANSITIONS_ENABLED,

  LAST_WIDGET_PROPERTY,
  PROP_HADJUSTMENT,
  PROP_VADJUSTMENT,
  PROP_HSCROLL_POLICY,
  PROP_VSCROLL_POLICY,

  LAST_PROPERTY
};

static GParamSpec *widget_props[LAST_WIDGET_PROPERTY] = { NULL, };


G_DEFINE_TYPE_WITH_CODE (GtkImageView, gtk_image_view, GTK_TYPE_WIDGET,
						 G_ADD_PRIVATE (GtkImageView)
						 G_IMPLEMENT_INTERFACE (GTK_TYPE_SCROLLABLE, NULL))

typedef struct _LoadTaskData LoadTaskData;

struct _LoadTaskData
{
  int scale_factor;
  gpointer source;
};


static void gtk_image_view_update_surface (GtkImageView    *image_view,
										   const GdkPixbuf *frame,
										   int              scale_factor);

static void adjustment_value_changed_cb (GtkAdjustment *adjustment,
										 gpointer       user_data);

static void gtk_image_view_update_adjustments (GtkImageView *image_view);

static void gtk_image_view_compute_bounding_box (GtkImageView *image_view,
												 double          *width,
												 double          *height,
												 double       *scale_out);
static void gtk_image_view_ensure_gestures (GtkImageView *image_view);

static inline void gtk_image_view_restrict_adjustment (GtkAdjustment *adjustment);
static void gtk_image_view_fix_anchor (GtkImageView *image_view,
									   double        anchor_x,
									   double        anchor_y,
									   State        *old_state);


static inline double
gtk_image_view_get_real_scale (GtkImageView *image_view)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);

  if (priv->in_zoom || priv->in_scale_transition)
	return priv->visible_scale;
  else
	return priv->scale;
}

static inline double
gtk_image_view_get_real_angle (GtkImageView *image_view)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);

  if (priv->in_rotate || priv->in_angle_transition)
	return priv->visible_angle;
  else
	return priv->angle;
}

static inline double
gtk_image_view_clamp_angle (double angle)
{
  double new_angle = angle;

  if (angle > 360.0)
	new_angle -= (int)(angle / 360.0) * 360;
  else if (angle < 0.0)
	new_angle += 360 - ((int)(angle  /360) * 360.0);

  g_assert (new_angle >= 0.0);
  g_assert (new_angle <= 360.0);

  return new_angle;
}

static inline int
gtk_image_view_get_snapped_angle (double angle)
{
  return (int) ((angle + 45.0) / 90.0) * 90;
}

static void
gtk_image_view_get_current_state (GtkImageView *image_view,
								  State        *state)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);

  if (priv->hadjustment != NULL && priv->vadjustment != NULL)
	{
	  state->hvalue = gtk_adjustment_get_value (priv->hadjustment);
	  state->vvalue = gtk_adjustment_get_value (priv->vadjustment);
	  state->hupper = gtk_adjustment_get_upper (priv->hadjustment);
	  state->vupper = gtk_adjustment_get_upper (priv->vadjustment);
	}
  state->angle = gtk_image_view_get_real_angle (image_view);
  state->scale = gtk_image_view_get_real_scale (image_view);
}

static gboolean
gtk_image_view_transitions_enabled (GtkImageView *image_view)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);
  gboolean animations_enabled;

  g_object_get (gtk_widget_get_settings (GTK_WIDGET (image_view)),
				"gtk-enable-animations", &animations_enabled,
				NULL);

  return priv->transitions_enabled && animations_enabled && priv->image_surface;
}

static gboolean
scale_frameclock_cb (GtkWidget     *widget,
					 GdkFrameClock *frame_clock,
					 gpointer       user_data)
{
  GtkImageView *image_view = GTK_IMAGE_VIEW (widget);
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);
  State state;
  gint64 now = gdk_frame_clock_get_frame_time (frame_clock);

  double t = (now - priv->scale_transition_start) / TRANSITION_DURATION;
  double new_scale = (priv->scale - priv->transition_start_scale) * t;

  gtk_image_view_get_current_state (image_view, &state);

  priv->visible_scale = priv->transition_start_scale + new_scale;
  priv->size_valid = FALSE;

  if (t >= 1.0)
	priv->in_scale_transition = FALSE;

  if (priv->hadjustment && priv->vadjustment)
	{
	  GtkAllocation allocation;
	  gtk_widget_get_allocation (widget, &allocation);
	  gtk_image_view_update_adjustments (image_view);

	  gtk_image_view_fix_anchor (image_view,
								 allocation.width / 2,
								 allocation.height / 2,
								 &state);
	}

  if (priv->fit_allocation)
	gtk_widget_queue_draw (widget);
  else
	gtk_widget_queue_resize (widget);

  if (t >= 1.0)
	{
	  priv->scale_transition_id = 0;
	  return G_SOURCE_REMOVE;
	}

  return G_SOURCE_CONTINUE;
}

static void
gtk_image_view_animate_to_scale (GtkImageView *image_view)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);

  if (priv->scale_transition_id != 0)
	gtk_widget_remove_tick_callback (GTK_WIDGET (image_view), priv->scale_transition_id);

  /* Target scale is priv->scale */
  priv->in_scale_transition = TRUE;
  priv->visible_scale = priv->scale;
  priv->transition_start_scale = priv->scale;
  priv->scale_transition_start = gdk_frame_clock_get_frame_time (gtk_widget_get_frame_clock (GTK_WIDGET (image_view)));

  priv->scale_transition_id = gtk_widget_add_tick_callback (GTK_WIDGET (image_view),
															scale_frameclock_cb,
															NULL, NULL);
}

static gboolean
angle_frameclock_cb (GtkWidget     *widget,
					 GdkFrameClock *frame_clock,
					 gpointer       user_data)
{
  GtkImageView *image_view = GTK_IMAGE_VIEW (widget);
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);
  int direction = GPOINTER_TO_INT (user_data);
  gint64 now = gdk_frame_clock_get_frame_time (frame_clock);
  State state;
  double target_angle = priv->angle;

  if (direction == 1 && target_angle < priv->transition_start_angle)
	target_angle += 360.0;
  else if (direction == 0 && target_angle > priv->transition_start_angle)
	target_angle -= 360.0;

  double t = (now - priv->angle_transition_start) / TRANSITION_DURATION;
  double new_angle = (target_angle - priv->transition_start_angle) * t;

  gtk_image_view_get_current_state (image_view, &state);

  priv->visible_angle = priv->transition_start_angle + new_angle;
  priv->size_valid = FALSE;

  if (t >= 1.0)
	priv->in_angle_transition = FALSE;

  if (priv->hadjustment && priv->vadjustment)
	{
	  GtkAllocation allocation;
	  gtk_widget_get_allocation (widget, &allocation);
	  gtk_image_view_update_adjustments (image_view);

	  gtk_image_view_fix_anchor (image_view,
								 allocation.width / 2,
								 allocation.height / 2,
								 &state);
	}

  if (priv->fit_allocation)
	gtk_widget_queue_draw (widget);
  else
	gtk_widget_queue_resize (widget);

  if (t >= 1.0)
	{
	  priv->angle_transition_id = 0;
	  return G_SOURCE_REMOVE;
	}

  return G_SOURCE_CONTINUE;
}

static void
gtk_image_view_animate_to_angle (GtkImageView *image_view,
								 int           direction)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);

  if (priv->angle_transition_id != 0)
	{
	  gtk_widget_remove_tick_callback (GTK_WIDGET (image_view), priv->angle_transition_id);
	  priv->angle_transition_id = 0;
	}

  /* Target angle is priv->angle */
  priv->in_angle_transition = TRUE;
  priv->visible_angle = priv->angle;
  priv->transition_start_angle = priv->angle;
  priv->angle_transition_start = gdk_frame_clock_get_frame_time (gtk_widget_get_frame_clock (GTK_WIDGET (image_view)));

  priv->angle_transition_id = gtk_widget_add_tick_callback (GTK_WIDGET (image_view),
															angle_frameclock_cb,
															GINT_TO_POINTER (direction),
															NULL);
}

static void
gtk_image_view_do_snapping (GtkImageView *image_view)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);
  double new_angle = gtk_image_view_get_snapped_angle (priv->angle);

  g_assert (priv->snap_angle);

  if (gtk_image_view_transitions_enabled (image_view))
	gtk_image_view_animate_to_angle (image_view, new_angle > priv->angle);

  priv->angle = new_angle;

  /* Don't notify! */
}

static void
free_load_task_data (LoadTaskData *data)
{
  g_clear_object (&data->source);
  g_slice_free (LoadTaskData, data);
}

static void
to_rotate_coords (GtkImageView *image_view,
				  State        *state,
				  double  in_x,  double  in_y,
				  double *out_x, double *out_y)
{
  double cx = state->hupper / 2.0 - state->hvalue;
  double cy = state->vupper / 2.0 - state->vvalue;

  *out_x = in_x - cx;
  *out_y = in_y - cy;
}

static void
gtk_image_view_fix_anchor (GtkImageView *image_view,
						   double        anchor_x,
						   double        anchor_y,
						   State        *old_state)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);
  double hupper_delta = gtk_adjustment_get_upper (priv->hadjustment)
						- old_state->hupper;
  double vupper_delta = gtk_adjustment_get_upper (priv->vadjustment)
						- old_state->vupper;
  double hupper_delta_scale, vupper_delta_scale;
  double hupper_delta_angle, vupper_delta_angle;
  double cur_scale = gtk_image_view_get_real_scale (image_view);

  g_assert (old_state->hupper > 0);
  g_assert (old_state->vupper > 0);
  g_assert (priv->hadjustment);
  g_assert (priv->vadjustment);
  g_assert (priv->size_valid);
  g_assert (anchor_x >= 0);
  g_assert (anchor_y >= 0);
  g_assert (anchor_x < gtk_widget_get_allocated_width (GTK_WIDGET (image_view)));
  g_assert (anchor_y < gtk_widget_get_allocated_height (GTK_WIDGET (image_view)));

  /* Amount of upper change caused by scale */
  hupper_delta_scale = ((old_state->hupper / old_state->scale) * cur_scale)
					   - old_state->hupper;
  vupper_delta_scale = ((old_state->vupper / old_state->scale) * cur_scale)
					   - old_state->vupper;

  /* Amount of upper change caused by angle */
  hupper_delta_angle = hupper_delta - hupper_delta_scale;
  vupper_delta_angle = vupper_delta - vupper_delta_scale;

  /* As a first step, fix the anchor point with regard to the
   * updated scale
   */
  {
	double hvalue = gtk_adjustment_get_value (priv->hadjustment);
	double vvalue = gtk_adjustment_get_value (priv->vadjustment);

	double px = anchor_x + hvalue;
	double py = anchor_y + vvalue;

	double px_after = (px / old_state->scale) * cur_scale;
	double py_after = (py / old_state->scale) * cur_scale;

	gtk_adjustment_set_value (priv->hadjustment,
							  hvalue + px_after - px);
	gtk_adjustment_set_value (priv->vadjustment,
							  vvalue + py_after - py);
  }

  gtk_adjustment_set_value (priv->hadjustment,
							gtk_adjustment_get_value (priv->hadjustment) + hupper_delta_angle / 2.0);

  gtk_adjustment_set_value (priv->vadjustment,
							gtk_adjustment_get_value (priv->vadjustment) + vupper_delta_angle / 2.0);

  {
	double rotate_anchor_x = 0;
	double rotate_anchor_y = 0;
	double anchor_angle;
	double anchor_length;
	double new_anchor_x, new_anchor_y;
	double delta_x, delta_y;

	/* Calculate the angle of the given anchor point relative to the
	 * bounding box center and the OLD state */
	to_rotate_coords (image_view, old_state,
					  anchor_x, anchor_y,
					  &rotate_anchor_x, &rotate_anchor_y);
	anchor_angle = atan2 (rotate_anchor_y, rotate_anchor_x);
	anchor_length = sqrt ((rotate_anchor_x * rotate_anchor_x) +
						  (rotate_anchor_y * rotate_anchor_y));

	/* The angle of the anchor point NOW is the old angle plus
	 * the difference between old surface angle and new surface angle */
	anchor_angle += DEG_TO_RAD (gtk_image_view_get_real_angle (image_view)
								- old_state->angle);

	/* Calculate the position of the new anchor point, relative
	 * to the bounding box center */
	new_anchor_x = cos (anchor_angle) * anchor_length;
	new_anchor_y = sin (anchor_angle) * anchor_length;

	/* The difference between old anchor and new anchor
	 * is what we care about... */
	delta_x = rotate_anchor_x - new_anchor_x;
	delta_y = rotate_anchor_y - new_anchor_y;

	/* At last, make the old anchor match the new anchor */
	gtk_adjustment_set_value (priv->hadjustment,
							  gtk_adjustment_get_value (priv->hadjustment) - delta_x);
	gtk_adjustment_set_value (priv->vadjustment,
							  gtk_adjustment_get_value (priv->vadjustment) - delta_y);

  }

  gtk_widget_queue_draw (GTK_WIDGET (image_view));
}

static void
gtk_image_view_compute_bounding_box (GtkImageView *image_view,
									 double       *width,
									 double       *height,
									 double       *scale_out)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);
  GtkAllocation alloc;
  double image_width;
  double image_height;
  double bb_width  = 0;
  double bb_height = 0;
  double upper_right_degrees;
  double upper_left_degrees;
  double r;
  double upper_right_x, upper_right_y;
  double upper_left_x, upper_left_y;
  double scale;
  double angle;

  if (priv->size_valid)
	{
	  *width = priv->cached_width;
	  *height = priv->cached_height;
	  if (scale_out)
		*scale_out = priv->cached_scale;
	  return;
	}

  if (!priv->image_surface)
	{
	  *width  = 0;
	  *height = 0;
	  return;
	}

  gtk_widget_get_allocation (GTK_WIDGET (image_view), &alloc);
  angle = gtk_image_view_get_real_angle (image_view);

  image_width  = cairo_image_surface_get_width (priv->image_surface)  / priv->scale_factor;
  image_height = cairo_image_surface_get_height (priv->image_surface) / priv->scale_factor;

  upper_right_degrees = DEG_TO_RAD (angle) + atan (image_height / image_width);
  upper_left_degrees  = DEG_TO_RAD (angle) + atan (image_height / -image_width);
  r = sqrt ((image_width / 2.0) * (image_width / 2.0) + (image_height / 2.0) * (image_height / 2.0));

  upper_right_x = r * cos (upper_right_degrees);
  upper_right_y = r * sin (upper_right_degrees);

  upper_left_x = r * cos (upper_left_degrees);
  upper_left_y = r * sin (upper_left_degrees);

  bb_width  = round (MAX (fabs (upper_right_x), fabs (upper_left_x)) * 2.0);
  bb_height = round (MAX (fabs (upper_right_y), fabs (upper_left_y)) * 2.0);

  if (priv->fit_allocation)
	{
	  double scale_x = (double)alloc.width / (double)bb_width;
	  double scale_y = (double)alloc.height / (double)bb_height;

	  scale = MIN (MIN (scale_x, scale_y), 1.0);
	}
  else
	{
	  scale = gtk_image_view_get_real_scale (image_view);
	}

  priv->cached_scale = scale;
  if (scale_out)
	*scale_out = scale;

  if (priv->fit_allocation)
	{
	  g_assert (!priv->scale_set);
	  priv->scale = scale;
	  g_object_notify_by_pspec (G_OBJECT (image_view),
								widget_props[PROP_SCALE]);
	}

  *width  = priv->cached_width  = bb_width  * scale;
  *height = priv->cached_height = bb_height * scale;

  priv->size_valid = TRUE;
}

static inline void
gtk_image_view_restrict_adjustment (GtkAdjustment *adjustment)
{
  double value     = gtk_adjustment_get_value (adjustment);
  double upper     = gtk_adjustment_get_upper (adjustment);
  double page_size = gtk_adjustment_get_page_size (adjustment);

  value = gtk_adjustment_get_value (adjustment);
  upper = gtk_adjustment_get_upper (adjustment);

  if (value > upper - page_size)
	gtk_adjustment_set_value (adjustment, upper - page_size);
  else if (value < 0)
	gtk_adjustment_set_value (adjustment, 0);
}

static void
gtk_image_view_update_adjustments (GtkImageView *image_view)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);
  double width, height;
  int widget_width  = gtk_widget_get_allocated_width  (GTK_WIDGET (image_view));
  int widget_height = gtk_widget_get_allocated_height (GTK_WIDGET (image_view));

  if (!priv->hadjustment && !priv->vadjustment)
	return;

  if (!priv->image_surface)
	{
	  if (priv->hadjustment)
		gtk_adjustment_configure (priv->hadjustment, 0, 0, 1, 0, 0, 1);

	  if (priv->vadjustment)
		gtk_adjustment_configure (priv->vadjustment, 0, 0, 1, 0, 0, 1);

	  return;
	}

  gtk_image_view_compute_bounding_box (image_view,
									   &width,
									   &height,
									   NULL);

  /* compute_bounding_box makes sure that the bounding box is never bigger than
   * the widget allocation if fit-allocation is set */
  if (priv->hadjustment)
	{
	  gtk_adjustment_set_upper (priv->hadjustment, MAX (width,  widget_width));
	  gtk_adjustment_set_page_size (priv->hadjustment, widget_width);
	  gtk_image_view_restrict_adjustment (priv->hadjustment);
	}

  if (priv->vadjustment)
	{
	  gtk_adjustment_set_upper (priv->vadjustment, MAX (height, widget_height));
	  gtk_adjustment_set_page_size (priv->vadjustment, widget_height);
	  gtk_image_view_restrict_adjustment (priv->vadjustment);
	}
}

static void
gtk_image_view_set_scale_internal (GtkImageView *image_view,
								   double        scale)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);
  scale = MAX (0, scale);

  priv->scale = scale;
  priv->size_valid = FALSE;
  g_object_notify_by_pspec (G_OBJECT (image_view),
							widget_props[PROP_SCALE]);

  if (priv->scale_set)
	{
	  priv->scale_set = FALSE;
	  g_object_notify_by_pspec (G_OBJECT (image_view),
								widget_props[PROP_SCALE_SET]);
	}

  if (priv->fit_allocation)
	{
	  priv->fit_allocation = FALSE;
	  g_object_notify_by_pspec (G_OBJECT (image_view),
								widget_props[PROP_FIT_ALLOCATION]);
	}

  gtk_image_view_update_adjustments (image_view);

  gtk_widget_queue_resize (GTK_WIDGET (image_view));
}

static void
gesture_zoom_begin_cb (GtkGesture       *gesture,
					   GdkEventSequence *sequence,
					   gpointer          user_data)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (user_data);

  if (!priv->zoomable ||
	  !priv->image_surface)
	{
	  gtk_gesture_set_state (gesture, GTK_EVENT_SEQUENCE_DENIED);
	  return;
	}

  if (priv->anchor_x == -1 && priv->anchor_y == -1)
	{
	  gtk_gesture_get_bounding_box_center (gesture,
										   &priv->anchor_x,
										   &priv->anchor_y);
	}
}

static void
gesture_zoom_end_cb (GtkGesture       *gesture,
					 GdkEventSequence *sequence,
					 gpointer          image_view)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);

  gtk_image_view_set_scale_internal (image_view, priv->visible_scale);

  priv->in_zoom = FALSE;
  priv->anchor_x = -1;
  priv->anchor_y = -1;
}

static void
gesture_zoom_cancel_cb (GtkGesture       *gesture,
						GdkEventSequence *sequence,
						gpointer          user_data)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (user_data);

  if (priv->in_zoom)
	gtk_image_view_set_scale (user_data, priv->gesture_start_scale);

  priv->in_zoom = FALSE;
  priv->anchor_x = -1;
  priv->anchor_y = -1;
}

static void
gesture_zoom_changed_cb (GtkGestureZoom *gesture,
						  double          delta,
						  GtkWidget      *widget)
{
  GtkImageView *image_view = GTK_IMAGE_VIEW (widget);
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);
  State state;
  double new_scale;

  if (!priv->in_zoom)
	{
	  priv->in_zoom = TRUE;
	  priv->gesture_start_scale = priv->scale;
	}

  if (priv->fit_allocation)
	{
	  priv->fit_allocation = FALSE;
	  g_object_notify_by_pspec (G_OBJECT (widget),
								widget_props[PROP_FIT_ALLOCATION]);
	}

  new_scale = priv->gesture_start_scale * delta;
  gtk_image_view_get_current_state (image_view, &state);

  priv->visible_scale = new_scale;
  priv->size_valid = FALSE;

  gtk_image_view_update_adjustments (image_view);

  if (priv->hadjustment != NULL && priv->vadjustment != NULL)
	{
	  gtk_image_view_fix_anchor (image_view,
								 priv->anchor_x,
								 priv->anchor_y,
								 &state);
	}

  gtk_widget_queue_resize (GTK_WIDGET (image_view));
}

static void
gesture_rotate_begin_cb (GtkGesture       *gesture,
						 GdkEventSequence *sequence,
						 gpointer          user_data)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (user_data);

  if (!priv->rotatable ||
	  !priv->image_surface)
	{
	  gtk_gesture_set_state (gesture, GTK_EVENT_SEQUENCE_DENIED);
	  return;
	}

  if (priv->anchor_x == -1 && priv->anchor_y == -1)
	{
	  gtk_gesture_get_bounding_box_center (gesture,
										   &priv->anchor_x,
										   &priv->anchor_y);
	}
}

static void
gesture_rotate_end_cb (GtkGesture       *gesture,
					   GdkEventSequence *sequence,
					   gpointer          image_view)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);

  priv->angle = gtk_image_view_clamp_angle (priv->visible_angle);

  if (priv->snap_angle)
	{
	  /* Will update priv->angle */
	  gtk_image_view_do_snapping (image_view);
	}
  g_object_notify_by_pspec (image_view,
							widget_props[PROP_ANGLE]);

  priv->in_rotate = FALSE;
  priv->anchor_x = -1;
  priv->anchor_y = -1;
}

static void
gesture_rotate_cancel_cb (GtkGesture       *gesture,
						  GdkEventSequence *sequence,
						  gpointer          image_view)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);

  priv->size_valid = FALSE;
  gtk_image_view_update_adjustments (image_view);

  priv->in_rotate = FALSE;
  priv->anchor_x = -1;
  priv->anchor_y = -1;
}

static void
gesture_rotate_changed_cb (GtkGestureRotate *gesture,
						  double            angle,
						  double            delta,
						  GtkWidget        *widget)
{
  GtkImageView *image_view = GTK_IMAGE_VIEW (widget);
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);
  State old_state;
  double new_angle;

  if (!priv->in_rotate)
	{
	  priv->in_rotate = TRUE;
	  priv->gesture_start_angle = priv->angle;
	}

  new_angle = priv->gesture_start_angle + RAD_TO_DEG (delta);
  gtk_image_view_get_current_state (image_view, &old_state);

  priv->visible_angle = new_angle;
  priv->size_valid = FALSE;
  gtk_image_view_update_adjustments (image_view);

  if (priv->hadjustment && priv->vadjustment && !priv->fit_allocation)
	gtk_image_view_fix_anchor (image_view,
							   priv->anchor_x,
							   priv->anchor_y,
							   &old_state);

  if (priv->fit_allocation)
	gtk_widget_queue_draw (widget);
  else
	gtk_widget_queue_resize (widget);
}

static void
gtk_image_view_ensure_gestures (GtkImageView *image_view)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);

  if (priv->zoomable && priv->zoom_gesture == NULL)
	{
	  priv->zoom_gesture = gtk_gesture_zoom_new (GTK_WIDGET (image_view));
	  g_signal_connect (priv->zoom_gesture, "scale-changed",
						(GCallback)gesture_zoom_changed_cb, image_view);
	  g_signal_connect (priv->zoom_gesture, "begin",
						(GCallback)gesture_zoom_begin_cb, image_view);
	  g_signal_connect (priv->zoom_gesture, "end",
						(GCallback)gesture_zoom_end_cb, image_view);
	  g_signal_connect (priv->zoom_gesture, "cancel",
						(GCallback)gesture_zoom_cancel_cb, image_view);
	}
  else if (!priv->zoomable && priv->zoom_gesture != NULL)
	{
	  g_clear_object (&priv->zoom_gesture);
	}

  if (priv->rotatable && priv->rotate_gesture == NULL)
	{
	  priv->rotate_gesture = gtk_gesture_rotate_new (GTK_WIDGET (image_view));
	  g_signal_connect (priv->rotate_gesture, "angle-changed", (GCallback)gesture_rotate_changed_cb, image_view);
	  g_signal_connect (priv->rotate_gesture, "begin", (GCallback)gesture_rotate_begin_cb, image_view);
	  g_signal_connect (priv->rotate_gesture, "end", (GCallback)gesture_rotate_end_cb, image_view);
	  g_signal_connect (priv->rotate_gesture, "cancel", (GCallback)gesture_rotate_cancel_cb, image_view);

	}
  else if (!priv->rotatable && priv->rotate_gesture != NULL)
	{
	  g_clear_object (&priv->rotate_gesture);
	}

  if (priv->zoom_gesture && priv->rotate_gesture)
	gtk_gesture_group (priv->zoom_gesture,
					   priv->rotate_gesture);
}

static void
gtk_image_view_init (GtkImageView *image_view)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);
  GtkWidget *widget = GTK_WIDGET (image_view);

  gtk_widget_set_can_focus (widget, TRUE);
  gtk_widget_set_has_window (widget, FALSE);

  priv->scale = 1.0;
  priv->angle = 0.0;
  priv->visible_scale = 1.0;
  priv->visible_angle = 0.0;
  priv->snap_angle = FALSE;
  priv->fit_allocation = FALSE;
  priv->scale_set = FALSE;
  priv->size_valid = FALSE;
  priv->anchor_x = -1;
  priv->anchor_y = -1;
  priv->rotatable = TRUE;
  priv->zoomable = TRUE;
  priv->transitions_enabled = TRUE;
  priv->angle_transition_id = 0;
  priv->scale_transition_id = 0;

  gtk_image_view_ensure_gestures (image_view);
}

static GdkPixbuf *
gtk_image_view_get_current_frame (GtkImageView *image_view)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);

  g_assert (priv->source_animation);

  if (priv->is_animation)
	return gdk_pixbuf_animation_iter_get_pixbuf (priv->source_animation_iter);
  else
	return gdk_pixbuf_animation_get_static_image (priv->source_animation);
}

static gboolean
gtk_image_view_update_animation (gpointer user_data)
{
  GtkImageView *image_view = user_data;
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);

  if (priv->is_animation)
	{
	  gdk_pixbuf_animation_iter_advance (priv->source_animation_iter, NULL);
	  gtk_image_view_update_surface (image_view,
									 gtk_image_view_get_current_frame (image_view),
									 priv->scale_factor);
	}

  return priv->is_animation;
}

static void
gtk_image_view_start_animation (GtkImageView *image_view)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);
  int delay_ms;

  g_assert (priv->is_animation);

  delay_ms = gdk_pixbuf_animation_iter_get_delay_time (priv->source_animation_iter);

  priv->animation_timeout = g_timeout_add (delay_ms, gtk_image_view_update_animation, image_view);
}

static void
gtk_image_view_stop_animation (GtkImageView *image_view)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);

  if (priv->animation_timeout != 0)
	{
	  g_assert (priv->is_animation);
	  g_source_remove (priv->animation_timeout);
	  priv->animation_timeout = 0;
	}
}

static gboolean
gtk_image_view_draw (GtkWidget *widget, cairo_t *ct)
{
  GtkImageView *image_view = GTK_IMAGE_VIEW (widget);
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);
  GtkStyleContext *sc = gtk_widget_get_style_context (widget);
  int widget_width = gtk_widget_get_allocated_width (widget);
  int widget_height = gtk_widget_get_allocated_height (widget);
  double draw_x = 0;
  double draw_y = 0;
  int image_width;
  int image_height;
  double draw_width;
  double draw_height;
  double scale = 0.0;

  if (priv->vadjustment && priv->hadjustment)
	{
	  int x = - gtk_adjustment_get_value (priv->hadjustment);
	  int y = - gtk_adjustment_get_value (priv->vadjustment);
	  int w = gtk_adjustment_get_upper (priv->hadjustment);
	  int h = gtk_adjustment_get_upper (priv->vadjustment);

	  gtk_render_background (sc, ct, x, y, w, h);
	  gtk_render_frame (sc, ct, x, y, w, h);
	}
  else
	{
	  gtk_render_background (sc, ct, 0, 0, widget_width, widget_height);
	  gtk_render_frame      (sc, ct, 0, 0, widget_width, widget_height);
	}

  if (!priv->image_surface)
	return GDK_EVENT_PROPAGATE;

  gtk_image_view_compute_bounding_box (image_view,
									   &draw_width, &draw_height,
									   &scale);

  if (draw_width == 0 || draw_height == 0)
	return GDK_EVENT_PROPAGATE;

  image_width  = cairo_image_surface_get_width (priv->image_surface)  * scale / priv->scale_factor;
  image_height = cairo_image_surface_get_height (priv->image_surface) * scale / priv->scale_factor;

  if (priv->hadjustment && priv->vadjustment)
	{
	  draw_x = (gtk_adjustment_get_page_size (priv->hadjustment) - image_width)  / 2.0;
	  draw_y = (gtk_adjustment_get_page_size (priv->vadjustment) - image_height) / 2.0;
	}
  else
	{
	  draw_x = (widget_width  - image_width)  / 2.0;
	  draw_y = (widget_height - image_height) / 2.0;
	}

  cairo_rectangle (ct, 0, 0, widget_width, widget_height);

  if (priv->hadjustment && draw_width >= widget_width)
	{
	  draw_x = (draw_width - image_width) / 2.0;
	  draw_x -= gtk_adjustment_get_value (priv->hadjustment);
	}

  if (priv->vadjustment && draw_height >= widget_height)
	{
	  draw_y = (draw_height - image_height) / 2.0;
	  draw_y -= gtk_adjustment_get_value (priv->vadjustment);
	}

  /* Rotate around the center */
  cairo_translate (ct,
				   draw_x + (image_width  / 2.0),
				   draw_y + (image_height / 2.0));
  cairo_rotate (ct, DEG_TO_RAD (gtk_image_view_get_real_angle (image_view)));
  cairo_translate (ct,
				   - draw_x - (image_width  / 2.0),
				   - draw_y - (image_height / 2.0));

  cairo_scale (ct, scale , scale );
  cairo_set_source_surface (ct,
							priv->image_surface,
							draw_x / scale ,
							draw_y / scale);
  cairo_pattern_set_filter (cairo_get_source (ct), CAIRO_FILTER_BILINEAR);
  cairo_fill (ct);

  return GDK_EVENT_PROPAGATE;
}

static void
gtk_image_view_set_hadjustment (GtkImageView  *image_view,
								GtkAdjustment *hadjustment)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);

  if (priv->hadjustment && priv->hadjustment == hadjustment)
	return;

  if (priv->hadjustment)
	{
	  g_signal_handlers_disconnect_by_func (priv->hadjustment, adjustment_value_changed_cb, image_view);
	  g_object_unref (priv->hadjustment);
	}

  if (hadjustment)
	{
	  g_signal_connect (G_OBJECT (hadjustment), "value-changed",
						G_CALLBACK (adjustment_value_changed_cb), image_view);
	  priv->hadjustment = g_object_ref_sink (hadjustment);
	}
  else
	{
	  priv->hadjustment = hadjustment;
	}

  g_object_notify (G_OBJECT (image_view), "hadjustment");

  gtk_image_view_update_adjustments (image_view);

  if (priv->fit_allocation)
	gtk_widget_queue_draw (GTK_WIDGET (image_view));
  else
	gtk_widget_queue_resize (GTK_WIDGET (image_view));

}

static void
gtk_image_view_set_vadjustment (GtkImageView  *image_view,
								GtkAdjustment *vadjustment)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);

  if (priv->vadjustment == vadjustment)
	return;

  if (priv->vadjustment)
	{
	  g_signal_handlers_disconnect_by_func (priv->vadjustment, adjustment_value_changed_cb, image_view);
	  g_object_unref (priv->vadjustment);
	}

  if (vadjustment)
	{
	  g_signal_connect ((GObject *)vadjustment, "value-changed",
						(GCallback) adjustment_value_changed_cb, image_view);
	  priv->vadjustment = g_object_ref_sink (vadjustment);
	}
  else
	{
	  priv->vadjustment = vadjustment;
	}

  g_object_notify (G_OBJECT (image_view), "vadjustment");

  gtk_image_view_update_adjustments (image_view);

  if (priv->fit_allocation)
	gtk_widget_queue_draw ((GtkWidget *)image_view);
  else
	gtk_widget_queue_resize ((GtkWidget *)image_view);
}

static void
gtk_image_view_set_hscroll_policy (GtkImageView        *image_view,
								   GtkScrollablePolicy  hscroll_policy)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);

  if (priv->hscroll_policy == hscroll_policy)
	return;

  priv->hscroll_policy = hscroll_policy;
}

static void
gtk_image_view_set_vscroll_policy (GtkImageView        *image_view,
								   GtkScrollablePolicy  vscroll_policy)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);

  if (priv->vscroll_policy == vscroll_policy)
	return;

  priv->vscroll_policy = vscroll_policy;
}

/**
 * gtk_image_view_set_scale:
 * @image_view: A #GtkImageView instance
 * @scale: The new scale value
 *
 * Sets the value of the #scale property. This will cause the
 * #scale-set property to be set to #FALSE as well
 *
 * If #GtkImageView:fit-allocation is %TRUE, it will be set to %FALSE, and @image_view
 * will be resized to the image's current size, taking the new scale into
 * account.
 *
 * If #GtkImageView:transitions-enabled is set to %TRUE, the internal scale value will be
 * interpolated between the old and the new scale, gtk_image_view_get_scale()
 * will report the one passed to gtk_image_view_set_scale() however.
 *
 * When calling this function, #GtkImageView will try to keep the currently centered
 * point of the image where it is, so visually it will "zoom" into the current
 * center of the widget. Note that #GtkImageView is a #GtkScrollable, so the center
 * of the image is also the center of the scrolled window in case it is packed into
 * a #GtkScrolledWindow.
 *
 */
void
gtk_image_view_set_scale (GtkImageView *image_view,
						  double        scale)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);
  State state;

  g_return_if_fail (GTK_IS_IMAGE_VIEW (image_view));
  g_return_if_fail (scale > 0.0);

  if (scale == priv->scale)
	return;

  gtk_image_view_get_current_state (image_view, &state);

  if (gtk_image_view_transitions_enabled (image_view))
	gtk_image_view_animate_to_scale (image_view);

  priv->scale = scale;
  g_object_notify_by_pspec (G_OBJECT (image_view),
							widget_props[PROP_SCALE]);

  if (priv->scale_set)
	{
	  priv->scale_set = FALSE;
	  g_object_notify_by_pspec (G_OBJECT (image_view),
								widget_props[PROP_SCALE_SET]);
	}

  if (priv->fit_allocation)
	{
	  priv->fit_allocation = FALSE;
	  g_object_notify_by_pspec (G_OBJECT (image_view),
								widget_props[PROP_FIT_ALLOCATION]);
	}

  priv->size_valid = FALSE;
  gtk_image_view_update_adjustments (image_view);

  if (!priv->image_surface)
	return;

  if (priv->hadjustment != NULL && priv->vadjustment != NULL)
	{
	  int pointer_x = gtk_widget_get_allocated_width (GTK_WIDGET (image_view)) / 2;
	  int pointer_y = gtk_widget_get_allocated_height (GTK_WIDGET (image_view)) / 2;
	  gtk_image_view_fix_anchor (image_view,
								 pointer_x,
								 pointer_y,
								 &state);
	}

  gtk_widget_queue_resize (GTK_WIDGET (image_view));
}

/**
 * gtk_image_view_get_scale:
 * @image_view: A #GtkImageView instance
 *
 * Returns: The current value of the #GtkImageView:scale property.
 *
 */
double
gtk_image_view_get_scale (GtkImageView *image_view)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);
  g_return_val_if_fail (GTK_IS_IMAGE_VIEW (image_view), 0.0);

  return priv->scale;
}

/**
 * gtk_image_view_set_angle:
 * @image_view: A #GtkImageView instance
 * @angle: The angle to rotate the image about, in
 *   degrees. If this is < 0 or > 360, the value will
 *   be wrapped. So e.g. setting this to 362 will result in a
 *   angle of 2, setting it to -2 will result in 358.
 *   Both 0 and 360 are possible.
 *
 * Sets the value of the #GtkImageView:angle property. When calling this function,
 * #GtkImageView will try to keep the currently centered point of the image where it is,
 * so visually the image will not be rotated around its center, but around the current
 * center of the widget. Note that #GtkImageView is a #GtkScrollable, so the center
 * of the image is also the center of the scrolled window in case it is packed into
 * a #GtkScrolledWindow.
 *
 */
void
gtk_image_view_set_angle (GtkImageView *image_view,
						  double        angle)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);
  State state;

  g_return_if_fail (GTK_IS_IMAGE_VIEW (image_view));

  if (angle == priv->angle)
	return;

  gtk_image_view_get_current_state (image_view, &state);

  if (gtk_image_view_transitions_enabled (image_view) &&
	  ABS(gtk_image_view_clamp_angle (angle) - priv->angle) > ANGLE_TRANSITION_MIN_DELTA)
	{
	  gtk_image_view_animate_to_angle (image_view, angle > priv->angle);
	}

  angle = gtk_image_view_clamp_angle (angle);

  if (priv->snap_angle)
	priv->angle = gtk_image_view_get_snapped_angle (angle);
  else
	priv->angle = angle;

  priv->size_valid = FALSE;

  gtk_image_view_update_adjustments (image_view);

  g_object_notify_by_pspec (G_OBJECT (image_view),
							widget_props[PROP_ANGLE]);

  if (!priv->image_surface)
	return;

  if (priv->hadjustment && priv->vadjustment && !priv->fit_allocation)
	{
	  int pointer_x = gtk_widget_get_allocated_width (GTK_WIDGET (image_view)) / 2;
	  int pointer_y = gtk_widget_get_allocated_height (GTK_WIDGET (image_view)) / 2;
	  gtk_image_view_fix_anchor (image_view,
								 pointer_x,
								 pointer_y,
								 &state);
	}

  if (priv->fit_allocation)
	gtk_widget_queue_draw (GTK_WIDGET (image_view));
  else
	gtk_widget_queue_resize (GTK_WIDGET (image_view));
}

/**
 * gtk_image_view_get_angle:
 * @image_view: A #GtkImageView instance
 *
 * Returns: The current angle value.
 *
 */
double
gtk_image_view_get_angle (GtkImageView *image_view)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);
  g_return_val_if_fail (GTK_IS_IMAGE_VIEW (image_view), 0.0);

  return priv->angle;
}

/**
 * gtk_image_view_set_snap_angle:
 * @image_view: A #GtkImageView instance
 * @snap_angle: The new value of the #GtkImageView:snap-angle property
 *
 * Setting #snap-angle to %TRUE will cause @image_view's  angle to
 * be snapped to 90° steps. Setting the #GtkImageView:angle property will cause it to
 * be set to the closest 90° step, so e.g. using an angle of 40 will result
 * in an angle of 0, using 240 will result in 270, etc.
 *
 */
void
gtk_image_view_set_snap_angle (GtkImageView *image_view,
							   gboolean     snap_angle)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);

  g_return_if_fail (GTK_IS_IMAGE_VIEW (image_view));

  snap_angle = !!snap_angle;

  if (snap_angle == priv->snap_angle)
	return;

  priv->snap_angle = snap_angle;
  g_object_notify_by_pspec (G_OBJECT (image_view),
							widget_props[PROP_SNAP_ANGLE]);

  if (priv->snap_angle)
	{
	  gtk_image_view_do_snapping (image_view);
	  g_object_notify_by_pspec (G_OBJECT (image_view),
								widget_props[PROP_ANGLE]);
	}
}

/**
 * gtk_image_view_get_snap_angle:
 * @image_view: A #GtkImageView instance
 *
 * Returns: The current value of the #GtkImageView:snap-angle property.
 *
 */
gboolean
gtk_image_view_get_snap_angle (GtkImageView *image_view)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);
  g_return_val_if_fail (GTK_IS_IMAGE_VIEW (image_view), FALSE);

  return priv->snap_angle;
}

/**
 * gtk_image_view_set_fit_allocation:
 * @image_view: A #GtkImageView instance
 * @fit_allocation: The new value of the #GtkImageView:fit-allocation property.
 *
 * Setting #GtkImageView:fit-allocation to %TRUE will cause the image to be scaled
 * to the widget's allocation, unless it would cause the image to be
 * scaled up.
 *
 * Setting #GtkImageView:fit-allocation will have the side effect of setting
 * #scale-set set to %FALSE, thus giving the #GtkImageView the control
 * over the image's scale. Additionally, if the new #GtkImageView:fit-allocation
 * value is %FALSE, the scale will be reset to 1.0 and the #GtkImageView
 * will be resized to take at least the image's real size.
 *
 */
void
gtk_image_view_set_fit_allocation (GtkImageView *image_view,
								   gboolean      fit_allocation)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);
  g_return_if_fail (GTK_IS_IMAGE_VIEW (image_view));

  fit_allocation = !!fit_allocation;

  if (fit_allocation == priv->fit_allocation)
	return;

  priv->fit_allocation = fit_allocation;
  g_object_notify_by_pspec (G_OBJECT (image_view),
							widget_props[PROP_FIT_ALLOCATION]);

  priv->scale_set = FALSE;
  priv->size_valid = FALSE;
  g_object_notify_by_pspec (G_OBJECT (image_view),
							widget_props[PROP_SCALE_SET]);

  if (!priv->fit_allocation)
	{
	  priv->scale = 1.0;
	  g_object_notify_by_pspec (G_OBJECT (image_view),
								widget_props[PROP_SCALE]);
	}

  gtk_image_view_update_adjustments (image_view);

  gtk_widget_queue_resize (GTK_WIDGET (image_view));
}

/**
 * gtk_image_view_get_fit_allocation:
 * @image_view: A #GtkImageView instance
 *
 * Returns: The current value of the #GtkImageView:fit-allocation property.
 *
 */
gboolean
gtk_image_view_get_fit_allocation (GtkImageView *image_view)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);
  g_return_val_if_fail (GTK_IS_IMAGE_VIEW (image_view), FALSE);

  return priv->fit_allocation;
}

/**
 * gtk_image_view_set_rotatable:
 * @image_view: A #GtkImageView instance
 * @rotatable: The new value of the #GtkImageView:rotatable property
 *
 * Sets the value of the #GtkImageView:rotatable property to @rotatable. This controls whether
 * the user can change the angle of the displayed image using a two-finger gesture.
 *
 */
void
gtk_image_view_set_rotatable (GtkImageView *image_view,
							  gboolean      rotatable)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);
  g_return_if_fail (GTK_IS_IMAGE_VIEW (image_view));

  rotatable = !!rotatable;

  if (priv->rotatable != rotatable)
	{
	  priv->rotatable = rotatable;
	  gtk_image_view_ensure_gestures (image_view);
	  g_object_notify_by_pspec (G_OBJECT (image_view),
								widget_props[PROP_ROTATABLE]);
	}
}

/**
 * gtk_image_view_get_rotatable:
 * @image_view: A #GtkImageView instance
 *
 * Returns: The current value of the #GtkImageView:rotatable property
 *
 */
gboolean
gtk_image_view_get_rotatable (GtkImageView *image_view)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);
  g_return_val_if_fail (GTK_IS_IMAGE_VIEW (image_view), FALSE);

  return priv->rotatable;
}

/**
 * gtk_image_view_set_zoomable:
 * @image_view: A #GtkImageView instance
 * @zoomable: The new value of the #GtkImageView:zoomable property
 *
 * Sets the new value of the #GtkImageView:zoomable property. This controls whether the user can
 * change the #GtkImageView:scale property using a two-finger gesture.
 *
 */
void
gtk_image_view_set_zoomable (GtkImageView *image_view,
							 gboolean      zoomable)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);
  g_return_if_fail (GTK_IS_IMAGE_VIEW (image_view));

  zoomable = !!zoomable;

  if (zoomable != priv->zoomable)
	{
	  priv->zoomable = zoomable;
	  gtk_image_view_ensure_gestures (image_view);
	  g_object_notify_by_pspec (G_OBJECT (image_view),
								widget_props[PROP_ZOOMABLE]);
	}
}

/**
 * gtk_image_view_get_zoomable:
 * @image_view: A #GtkImageView instance
 *
 * Returns: The current value of the #GtkImageView:zoomable property.
 *
 */
gboolean
gtk_image_view_get_zoomable (GtkImageView *image_view)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);
  g_return_val_if_fail (GTK_IS_IMAGE_VIEW (image_view), FALSE);

  return priv->zoomable;
}

/**
 * gtk_image_view_set_transitions_enabled:
 * @image_view: A #GtkImageView instance
 * @transitions_enabled: The new value of the #GtkImageView:transitions-enabled property
 *
 * Sets the new value of the #GtkImageView:transitions-enabled property.
 * Note that even if #GtkImageView:transitions-enabled is %TRUE, transitions will
 * not be used if #GtkSettings:gtk-enable-animations is %FALSE.
 *
 */
void
gtk_image_view_set_transitions_enabled (GtkImageView *image_view,
										gboolean      transitions_enabled)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);
  g_return_if_fail (GTK_IS_IMAGE_VIEW (image_view));

  transitions_enabled = !!transitions_enabled;

  if (transitions_enabled != priv->transitions_enabled)
	{
	  priv->transitions_enabled = transitions_enabled;
	  g_object_notify_by_pspec (G_OBJECT (image_view),
								widget_props[PROP_TRANSITIONS_ENABLED]);
	}
}

/**
 * gtk_image_view_get_transitions_enabled:
 * @image_view: A #GtkImageView instance
 *
 * Returns: the current value of the #GtkImageView:transitions-enabled property.
 *
 */
gboolean
gtk_image_view_get_transitions_enabled (GtkImageView *image_view)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);
  g_return_val_if_fail (GTK_IS_IMAGE_VIEW (image_view), FALSE);

  return priv->transitions_enabled;
}

/**
 * gtk_image_view_get_scale_set:
 * @image_view: A #GtkImageView instance
 *
 * Returns: the current value of the #GtkImageView:scale-set property.
 *
 */
gboolean
gtk_image_view_get_scale_set (GtkImageView *image_view)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);
  g_return_val_if_fail (GTK_IS_IMAGE_VIEW (image_view), FALSE);

  return priv->scale_set;
}

static void
gtk_image_view_realize (GtkWidget *widget)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (GTK_IMAGE_VIEW (widget));
  GtkAllocation allocation;
  GdkWindowAttr attributes = { 0, };
  GdkWindow *window;

  gtk_widget_get_allocation (widget, &allocation);
  gtk_widget_set_realized (widget, TRUE);

  attributes.x = allocation.x;
  attributes.y = allocation.y;
  attributes.width  = allocation.width;
  attributes.height = allocation.height;
  attributes.window_type = GDK_WINDOW_CHILD;
  attributes.event_mask = gtk_widget_get_events (widget) |
						  GDK_POINTER_MOTION_MASK |
						  GDK_BUTTON_PRESS_MASK |
						  GDK_BUTTON_RELEASE_MASK |
						  GDK_SMOOTH_SCROLL_MASK |
						  GDK_SCROLL_MASK |
						  GDK_TOUCH_MASK;
  attributes.wclass = GDK_INPUT_ONLY;

  window = gtk_widget_get_parent_window (widget);

  gtk_widget_set_window (widget, window);
  g_object_ref (G_OBJECT (window));

  window = gdk_window_new (gtk_widget_get_parent_window (widget),
						   &attributes, GDK_WA_X | GDK_WA_Y);
  priv->event_window = window;

  gtk_widget_register_window (widget, priv->event_window);
  gdk_window_set_user_data (window, widget);
}

static void
gtk_image_view_unrealize (GtkWidget *widget)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (GTK_IMAGE_VIEW (widget));

  if (priv->event_window)
	{
	  gtk_widget_unregister_window (widget, priv->event_window);
	  gdk_window_destroy (priv->event_window);
	  priv->event_window = NULL;
	}

  GTK_WIDGET_CLASS (gtk_image_view_parent_class)->unrealize (widget);
}

static void
gtk_image_view_size_allocate (GtkWidget     *widget,
							  GtkAllocation *allocation)
{
  GtkImageView *image_view = GTK_IMAGE_VIEW (widget);
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);

  gtk_widget_set_allocation (widget, allocation);

  if (gtk_widget_get_realized (widget))
	{
	  gdk_window_move_resize (priv->event_window,
							  allocation->x, allocation->y,
							  allocation->width, allocation->height);
	}

  if (priv->fit_allocation)
	priv->size_valid = FALSE;

  gtk_image_view_update_adjustments (image_view);
}

static void
gtk_image_view_map (GtkWidget *widget)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (GTK_IMAGE_VIEW (widget));

  if (priv->is_animation)
	gtk_image_view_start_animation (GTK_IMAGE_VIEW (widget));

  if (priv->event_window)
	gdk_window_show (priv->event_window);

  GTK_WIDGET_CLASS (gtk_image_view_parent_class)->map (widget);
}

static void
gtk_image_view_unmap (GtkWidget *widget)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (GTK_IMAGE_VIEW (widget));

  if (priv->is_animation)
	gtk_image_view_stop_animation (GTK_IMAGE_VIEW (widget));

  GTK_WIDGET_CLASS (gtk_image_view_parent_class)->unmap (widget);
}

static void
adjustment_value_changed_cb (GtkAdjustment *adjustment,
							 gpointer       user_data)
{
  GtkImageView *image_view = user_data;

  gtk_image_view_update_adjustments (image_view);

  gtk_widget_queue_draw (GTK_WIDGET (image_view));
}

static void
gtk_image_view_get_preferred_height (GtkWidget *widget,
									 int       *minimal,
									 int       *natural)
{
  GtkImageView *image_view  = GTK_IMAGE_VIEW (widget);
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);

  double width, height;
  gtk_image_view_compute_bounding_box (image_view,
									   &width,
									   &height,
									   NULL);

  if (priv->fit_allocation)
	{
	  *minimal = 0;
	  *natural = height;
	}
  else
	{
	  *minimal = height;
	  *natural = height;
	}
}

static void
gtk_image_view_get_preferred_width (GtkWidget *widget,
									int       *minimal,
									int       *natural)
{
  GtkImageView *image_view  = GTK_IMAGE_VIEW (widget);
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);
  double width, height;

  gtk_image_view_compute_bounding_box (image_view,
									   &width,
									   &height,
									   NULL);
  if (priv->fit_allocation)
	{
	  *minimal = 0;
	  *natural = width;
	}
  else
	{
	  *minimal = width;
	  *natural = width;
	}
}

static gboolean
gtk_image_view_scroll_event (GtkWidget       *widget,
							 GdkEventScroll  *event)
{
  GtkImageView *image_view = GTK_IMAGE_VIEW (widget);
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);
  double new_scale = priv->scale - (0.1 * event->delta_y);
  State state;

  if (!priv->image_surface ||
	  !priv->zoomable)
	return GDK_EVENT_PROPAGATE;

  if (event->state & GDK_SHIFT_MASK ||
	  event->state & GDK_CONTROL_MASK)
	return GDK_EVENT_PROPAGATE;

  gtk_image_view_get_current_state (image_view, &state);

  gtk_image_view_set_scale_internal (image_view, new_scale);

  if (priv->hadjustment && priv->vadjustment)
	{
	  gtk_image_view_fix_anchor (image_view,
								 event->x,
								 event->y,
								 &state);
	}

  return GDK_EVENT_STOP;
}

static void
gtk_image_view_set_property (GObject      *object,
							 guint         prop_id,
							 const GValue *value,
							 GParamSpec   *pspec)

{
  GtkImageView *image_view = (GtkImageView *) object;

  switch (prop_id)
	{
	  case PROP_SCALE:
		gtk_image_view_set_scale (image_view, g_value_get_double (value));
		break;
	  case PROP_ANGLE:
		gtk_image_view_set_angle (image_view, g_value_get_double (value));
		break;
	  case PROP_SNAP_ANGLE:
		gtk_image_view_set_snap_angle (image_view, g_value_get_boolean (value));
		break;
	  case PROP_FIT_ALLOCATION:
		gtk_image_view_set_fit_allocation (image_view, g_value_get_boolean (value));
		break;
	  case PROP_ROTATABLE:
		gtk_image_view_set_rotatable (image_view, g_value_get_boolean (value));
		break;
	  case PROP_ZOOMABLE:
		gtk_image_view_set_zoomable (image_view, g_value_get_boolean (value));
		break;
	  case PROP_TRANSITIONS_ENABLED:
		gtk_image_view_set_transitions_enabled (image_view, g_value_get_boolean (value));
		break;
	  case PROP_HADJUSTMENT:
		gtk_image_view_set_hadjustment (image_view, g_value_get_object (value));
		break;
	   case PROP_VADJUSTMENT:
		gtk_image_view_set_vadjustment (image_view, g_value_get_object (value));
		break;
	  case PROP_HSCROLL_POLICY:
		gtk_image_view_set_hscroll_policy (image_view, g_value_get_enum (value));
		break;
	  case PROP_VSCROLL_POLICY:
		gtk_image_view_set_vscroll_policy (image_view, g_value_get_enum (value));
		break;
	  default:
		G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
	}
}

static void
gtk_image_view_get_property (GObject    *object,
							 guint       prop_id,
							 GValue     *value,
							 GParamSpec *pspec)
{
  GtkImageView *image_view  = (GtkImageView *)object;
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);
  switch (prop_id)
	{
	  case PROP_SCALE:
		g_value_set_double (value, priv->scale);
		break;
	  case PROP_SCALE_SET:
		g_value_set_boolean (value, priv->scale_set);
		break;
	  case PROP_ANGLE:
		g_value_set_double (value, priv->angle);
		break;
	  case PROP_SNAP_ANGLE:
		g_value_set_boolean (value, priv->snap_angle);
		break;
	  case PROP_FIT_ALLOCATION:
		g_value_set_boolean (value, priv->fit_allocation);
		break;
	  case PROP_ROTATABLE:
		g_value_set_boolean (value, priv->rotatable);
		break;
	  case PROP_ZOOMABLE:
		g_value_set_boolean (value, priv->zoomable);
		break;
	  case PROP_TRANSITIONS_ENABLED:
		g_value_set_boolean (value, priv->transitions_enabled);
		break;
	  case PROP_HADJUSTMENT:
		g_value_set_object (value, priv->hadjustment);
		break;
	  case PROP_VADJUSTMENT:
		g_value_set_object (value, priv->vadjustment);
		break;
	  case PROP_HSCROLL_POLICY:
		g_value_set_enum (value, priv->hscroll_policy);
		break;
	  case PROP_VSCROLL_POLICY:
		g_value_set_enum (value, priv->vscroll_policy);
		break;
	  default:
		G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
	}
}

static void
gtk_image_view_finalize (GObject *object)
{
  GtkImageView *image_view  = (GtkImageView *)object;
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);

  gtk_image_view_stop_animation (image_view);

  g_clear_object (&priv->source_animation);

  g_clear_object (&priv->rotate_gesture);
  g_clear_object (&priv->zoom_gesture);

  g_clear_object (&priv->hadjustment);
  g_clear_object (&priv->vadjustment);

  if (priv->image_surface)
	cairo_surface_destroy (priv->image_surface);

  G_OBJECT_CLASS (gtk_image_view_parent_class)->finalize (object);
}

static void
gtk_image_view_class_init (GtkImageViewClass *view_class)
{
  GObjectClass   *object_class = G_OBJECT_CLASS (view_class);
  GtkWidgetClass *widget_class = GTK_WIDGET_CLASS (view_class);

  object_class->set_property = gtk_image_view_set_property;
  object_class->get_property = gtk_image_view_get_property;
  object_class->finalize     = gtk_image_view_finalize;

  widget_class->draw          = gtk_image_view_draw;
  widget_class->realize       = gtk_image_view_realize;
  widget_class->unrealize     = gtk_image_view_unrealize;
  widget_class->size_allocate = gtk_image_view_size_allocate;
  widget_class->map           = gtk_image_view_map;
  widget_class->unmap         = gtk_image_view_unmap;
  widget_class->scroll_event  = gtk_image_view_scroll_event;
  widget_class->get_preferred_width  = gtk_image_view_get_preferred_width;
  widget_class->get_preferred_height = gtk_image_view_get_preferred_height;

  /**
   * GtkImageView:scale:
   * The scale the internal surface gets drawn with.
   *
   */
  widget_props[PROP_SCALE] = g_param_spec_double ("scale",
												  "Scale",
												  "The scale the internal surface gets drawn with",
												  0.0,
												  G_MAXDOUBLE,
												  1.0,
												  _PARAM_READWRITE|G_PARAM_EXPLICIT_NOTIFY);
  /**
   * GtkImageView:scale-set:
   * Whether or not the current value of the scale property was set by the user.
   * This is to distringuish between scale values set by the #GtkImageView itself,
   * e.g. when #GtkImageView:fit-allocation is true, which will change the scale
   * depending on the widget allocation.
   *
   */
  widget_props[PROP_SCALE_SET] = g_param_spec_boolean ("scale-set",
													   "Scale Set",
													   "Wheter the scale property has been set by the user or by GtkImageView itself",
													   FALSE,
													   _PARAM_READABLE|G_PARAM_EXPLICIT_NOTIFY);
  /**
   * GtkImageView:angle:
   * The angle the surface gets rotated about.
   * This is in degrees and we rotate clock-wise.
   *
   */
  widget_props[PROP_ANGLE] = g_param_spec_double ("angle",
												  "Angle",
												  "The angle the internal surface gets rotated about",
												  0.0,
												  360.0,
												  0.0,
												  _PARAM_READWRITE|G_PARAM_EXPLICIT_NOTIFY);
  /**
   * GtkImageView:rotatable:
   * Whether or not the image can be rotated using a two-finger rotate gesture.
   *
   */
  widget_props[PROP_ROTATABLE] = g_param_spec_boolean ("rotatable",
													   "Rotatable",
													   "Controls user-rotatability",
													   TRUE,
													   _PARAM_READWRITE|G_PARAM_EXPLICIT_NOTIFY);
/**
   * GtkImageView:zoomable:
   * Whether or not the image can be scaled using a two-finger zoom gesture, as well as
   * scrolling on the #GtkImageView.
   *
   */
  widget_props[PROP_ZOOMABLE] = g_param_spec_boolean ("zoomable",
													  "Zoomable",
													  "Controls user-zoomability",
													  TRUE,
													  _PARAM_READWRITE|G_PARAM_EXPLICIT_NOTIFY);
/**
   * GtkImageView:snap-angle:
   * Whether or not the angle property snaps to 90° steps. If this is enabled
   * and the angle property gets set to a non-90° step, the new value will be
   * set to the closest 90° step. If #GtkImageView:transitions-enabled is %TRUE,
   * the angle change from the current angle to the new angle will be interpolated.
   *
   */
  widget_props[PROP_SNAP_ANGLE] = g_param_spec_boolean ("snap-angle",
														"Snap Angle",
														"Snap angle to 90° steps",
														FALSE,
														_PARAM_READWRITE|G_PARAM_EXPLICIT_NOTIFY);

  /**
   * GtkImageView:fit-allocation:
   * If this is %TRUE, the scale the image will be drawn in will depend on the current
   * widget allocation. The image will be scaled down to fit into the widget allocation,
   * but never scaled up. The aspect ratio of the image will be kept at all times.
   *
   */
  widget_props[PROP_FIT_ALLOCATION] = g_param_spec_boolean ("fit-allocation",
															"Fit Allocation",
															"Scale the image down to fit into the widget allocation",
															FALSE,
															_PARAM_READWRITE|G_PARAM_EXPLICIT_NOTIFY);

  /**
   *  GtkImageView:transitions-enabled
   *
   *  Whether or not certain property changes will be interpolated. This affects a variety
   *  of function calls on a #GtkImageView instance, e.g. setting the angle property, the
   *  scale property, but also the angle snapping in case #GtkImageView:snap-angle is set.
   *
   *  Note that the transitions in #GtkImageView never apply to the actual property values
   *  set and instead interpolate between the visual angle/scale, so you cannot depend on
   *  getting 60 notify signal emissions per second.
   *
   */
  widget_props[PROP_TRANSITIONS_ENABLED] = g_param_spec_boolean ("transitions-enabled",
																 "Transitions Enabled",
																 "Whether scale and angle changes get interpolated",
																 TRUE,
																 _PARAM_READWRITE|G_PARAM_EXPLICIT_NOTIFY);

  g_object_class_install_properties (object_class, LAST_WIDGET_PROPERTY, widget_props);

  g_object_class_override_property (object_class, PROP_HADJUSTMENT,    "hadjustment");
  g_object_class_override_property (object_class, PROP_VADJUSTMENT,    "vadjustment");
  g_object_class_override_property (object_class, PROP_HSCROLL_POLICY, "hscroll-policy");
  g_object_class_override_property (object_class, PROP_VSCROLL_POLICY, "vscroll-policy");

}

/**
 * gtk_image_view_new:
 *
 * Returns: A newly created #GtkImageView instance.
 *
 */
GtkWidget *
gtk_image_view_new ()
{
  return g_object_new (GTK_TYPE_IMAGE_VIEW, NULL);
}

static void
gtk_image_view_replace_surface (GtkImageView    *image_view,
								cairo_surface_t *surface,
								int              scale_factor)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);

  if (priv->image_surface)
	cairo_surface_destroy (priv->image_surface);

  if (scale_factor == 0)
	priv->scale_factor = gtk_widget_get_scale_factor (GTK_WIDGET (image_view));
  else
	priv->scale_factor = scale_factor;

  priv->image_surface = surface;
  priv->size_valid = FALSE;

  if (surface)
	cairo_surface_reference (priv->image_surface);
}

static void
gtk_image_view_update_surface (GtkImageView    *image_view,
							   const GdkPixbuf *frame,
							   int              scale_factor)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);
  GdkWindow *window = gtk_widget_get_window (GTK_WIDGET (image_view));
  cairo_surface_t *new_surface;
  gboolean size_changed = TRUE;

  new_surface = gdk_cairo_surface_create_from_pixbuf (frame,
													  scale_factor,
													  window);

  if (priv->image_surface)
	{
	  size_changed = (cairo_image_surface_get_width (priv->image_surface) !=
					  cairo_image_surface_get_width (new_surface)) ||
					 (cairo_image_surface_get_height (priv->image_surface) !=
					  cairo_image_surface_get_height (new_surface)) ||
					 (scale_factor != priv->scale_factor);
	}

  gtk_image_view_replace_surface (image_view,
								  new_surface,
								  scale_factor);

  if (priv->fit_allocation || !size_changed)
	gtk_widget_queue_draw (GTK_WIDGET (image_view));
  else
	gtk_widget_queue_resize (GTK_WIDGET (image_view));

  g_assert (priv->image_surface != NULL);
}

static void
gtk_image_view_replace_animation (GtkImageView       *image_view,
								  GdkPixbufAnimation *animation,
								  int                 scale_factor)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);

  if (priv->source_animation)
	{
	  g_assert (priv->image_surface);
	  if (priv->is_animation)
		{
		  gtk_image_view_stop_animation (image_view);
		  g_clear_object (&priv->source_animation_iter);
		}
	}

  priv->is_animation = !gdk_pixbuf_animation_is_static_image (animation);

  if (priv->is_animation)
	{
	  priv->source_animation = animation;
	  priv->source_animation_iter = gdk_pixbuf_animation_get_iter (priv->source_animation,
																   NULL);
	  gtk_image_view_update_surface (image_view,
									 gtk_image_view_get_current_frame (image_view),
									 scale_factor);

	  gtk_image_view_start_animation (image_view);
	}
  else
	{
	  gtk_image_view_update_surface (image_view,
									 gdk_pixbuf_animation_get_static_image (animation),
									 scale_factor);
	  g_object_unref (animation);
	}

}

static void
gtk_image_view_load_image_from_stream (GtkImageView *image_view,
									   GInputStream *input_stream,
									   int           scale_factor,
									   GCancellable *cancellable,
									   GError       *error)
{
  GdkPixbufAnimation *result;

  g_assert (error == NULL);
  result = gdk_pixbuf_animation_new_from_stream (input_stream,
												 cancellable,
												 &error);

  if (!error)
	gtk_image_view_replace_animation (image_view, result, scale_factor);

  g_object_unref (input_stream);
}

static void
gtk_image_view_load_image_contents (GTask        *task,
									gpointer      source_object,
									gpointer      task_data,
									GCancellable *cancellable)
{
  GtkImageView *image_view = source_object;
  LoadTaskData *data = task_data;
  GFile *file = G_FILE (data->source);
  GError *error = NULL;
  GFileInputStream *in_stream;

  in_stream = g_file_read (file, cancellable, &error);

  if (error)
	{
	  /* in_stream is NULL */
	  g_object_unref (file);
	  g_task_return_error (task, error);
	  return;
	}

  /* Closes and unrefs the input stream */
  gtk_image_view_load_image_from_stream (image_view,
										 G_INPUT_STREAM (in_stream),
										 data->scale_factor,
										 cancellable,
										 error);

  if (error)
	g_task_return_error (task, error);
  else
	g_task_return_boolean (task, TRUE);
}

static void
gtk_image_view_load_from_input_stream (GTask        *task,
									   gpointer      source_object,
									   gpointer      task_data,
									   GCancellable *cancellable)
{
  GtkImageView *image_view = source_object;
  LoadTaskData *data = task_data;
  GInputStream *in_stream = G_INPUT_STREAM (data->source);
  GError *error = NULL;

  /* Closes and unrefs the input stream */
  gtk_image_view_load_image_from_stream (image_view,
										 in_stream,
										 data->scale_factor,
										 cancellable,
										 error);

  if (error)
	g_task_return_error (task, error);
  else
	g_task_return_boolean (task, TRUE);
}

/**
 * gtk_image_view_load_from_file_async:
 * @image_view: A #GtkImageView instance
 * @file: The file to read from
 * @scale_factor: Scale factor of the image. Pass 0 to use the
 *   scale factor of @image_view
 * @cancellable: (nullable): A #GCancellable that can be used to
 *   cancel the loading operation
 * @callback: (scope async): Callback to call once the operation finished
 * @user_data: (closure): Data to pass to @callback
 *
 * Asynchronously loads an image from the given file.
 *
 */
void
gtk_image_view_load_from_file_async (GtkImageView        *image_view,
									 GFile               *file,
									 int                  scale_factor,
									 GCancellable        *cancellable,
									 GAsyncReadyCallback  callback,
									 gpointer             user_data)
{
  GTask *task;
  LoadTaskData *task_data;
  g_return_if_fail (GTK_IS_IMAGE_VIEW (image_view));
  g_return_if_fail (G_IS_FILE (file));
  g_return_if_fail (scale_factor >= 0);

  task_data = g_slice_new (LoadTaskData);
  task_data->scale_factor = scale_factor;
  task_data->source = file;
  g_object_ref (file);

  task = g_task_new (image_view, cancellable, callback, user_data);
  g_task_set_task_data (task, task_data, (GDestroyNotify)free_load_task_data);
  g_task_run_in_thread (task, gtk_image_view_load_image_contents);

  g_object_unref (task);
}

/**
 * gtk_image_view_load_from_file_finish:
 * @image_view: A #GtkImageView instance
 * @result: A #GAsyncResult
 * @error: (nullable): Location to store error information in case the operation fails
 *
 * Finished an asynchronous operation started with gtk_image_view_load_from_file_async().
 *
 * Returns: %TRUE if the operation succeeded, %FALSE otherwise,
 * in which case @error will be set.
 *
 */
gboolean
gtk_image_view_load_from_file_finish   (GtkImageView  *image_view,
										GAsyncResult  *result,
										GError       **error)
{
  g_return_val_if_fail (g_task_is_valid (result, image_view), FALSE);

  return g_task_propagate_boolean (G_TASK (result), error);
}

/**
 * gtk_image_view_load_from_stream_async:
 * @image_view: A #GtkImageView instance
 * @input_stream: (transfer full): Input stream to read from
 * @scale_factor: The scale factor of the image. Pass 0 to use the scale factor
 *   of @image_view.
 * @cancellable: (nullable): The #GCancellable used to cancel the operation
 * @callback: (scope async): A #GAsyncReadyCallback invoked when the operation finishes
 * @user_data: (closure): The data to pass to @callback
 *
 * Asynchronously loads an image from the given input stream.
 *
 */
void
gtk_image_view_load_from_stream_async (GtkImageView        *image_view,
									   GInputStream        *input_stream,
									   int                  scale_factor,
									   GCancellable        *cancellable,
									   GAsyncReadyCallback  callback,
									   gpointer             user_data)
{
  GTask *task;
  LoadTaskData *task_data;
  g_return_if_fail (GTK_IS_IMAGE_VIEW (image_view));
  g_return_if_fail (G_IS_INPUT_STREAM (input_stream));
  g_return_if_fail (scale_factor >= 0);

  task_data = g_slice_new (LoadTaskData);
  task_data->scale_factor = scale_factor;
  task_data->source = input_stream;

  task = g_task_new (image_view, cancellable, callback, user_data);
  g_task_set_task_data (task, task_data, (GDestroyNotify)free_load_task_data);
  g_task_run_in_thread (task, gtk_image_view_load_from_input_stream);

  g_object_unref (task);
}

/**
 * gtk_image_view_load_from_stream_finish:
 * @image_view: A #GtkImageView instance
 * @result: A #GAsyncResult
 * @error: (nullable): Location to store error information on failure
 *
 * Finishes an asynchronous operation started by gtk_image_view_load_from_stream_async().
 *
 * Returns: %TRUE if the operation finished successfully, %FALSE otherwise.
 *
 */
gboolean
gtk_image_view_load_from_stream_finish (GtkImageView  *image_view,
										GAsyncResult  *result,
										GError       **error)
{
  g_return_val_if_fail (g_task_is_valid (result, image_view), FALSE);

  return g_task_propagate_boolean (G_TASK (result), error);
}

/**
 * gtk_image_view_set_pixbuf:
 * @image_view: A #GtkImageView instance
 * @pixbuf: (transfer none): A #GdkPixbuf instance
 * @scale_factor: The scale factor of the pixbuf. Pass 0 to use the scale factor
 *   of @image_view
 *
 * Sets the internal image to @pixbuf. @image_view will not take ownership of @pixbuf,
 * so it will not unref or free it in any way. If you want to unset the internal
 * image data, look at gtk_image_view_set_surface().
 *
 */
void
gtk_image_view_set_pixbuf (GtkImageView    *image_view,
						   const GdkPixbuf *pixbuf,
						   int              scale_factor)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);

  g_return_if_fail (GTK_IS_IMAGE_VIEW (image_view));
  g_return_if_fail (GDK_IS_PIXBUF (pixbuf));
  g_return_if_fail (scale_factor >= 0);

  if (priv->is_animation)
	{
	  g_clear_object (&priv->source_animation);
	  gtk_image_view_stop_animation (image_view);
	  priv->is_animation = FALSE;
	}

  gtk_image_view_update_surface (image_view, pixbuf, scale_factor);

  gtk_image_view_update_adjustments (image_view);

  /* gtk_image_view_update_surface already calls queue_draw/queue_resize */
}

/**
 * gtk_image_view_set_surface:
 * @image_view: A #GtkImageView instance
 * @surface: (nullable) (transfer full): A #cairo_surface_t of type %CAIRO_SURFACE_TYPE_IMAGE, or
 *   %NULL to unset any internal image data.
 *
 * Sets the internal surface to @surface. @image_view will assume ownership of this surface.
 * You can use this function to unset any internal image data by passing %NULL as @surface.
 *
 */
void
gtk_image_view_set_surface (GtkImageView    *image_view,
							cairo_surface_t *surface)
{
  GtkImageViewPrivate *priv = gtk_image_view_get_instance_private (image_view);
  double scale_x = 0.0;
  double scale_y;

  g_return_if_fail (GTK_IS_IMAGE_VIEW (image_view));

  if (surface)
	{
	  g_return_if_fail (cairo_surface_get_type (surface) == CAIRO_SURFACE_TYPE_IMAGE);

	  cairo_surface_get_device_scale (surface, &scale_x, &scale_y);

	  g_return_if_fail (scale_x == scale_y);
	}

  if (priv->is_animation)
	{
	  g_clear_object (&priv->source_animation);
	  gtk_image_view_stop_animation (image_view);
	  priv->is_animation = FALSE;
	}

  gtk_image_view_replace_surface (image_view,
								  surface,
								  scale_x);

  gtk_image_view_update_adjustments (image_view);

  if (priv->fit_allocation)
	gtk_widget_queue_draw (GTK_WIDGET (image_view));
  else
	gtk_widget_queue_resize (GTK_WIDGET (image_view));
}

/**
 * gtk_image_view_set_animation:
 * @image_view: A #GtkImageView instance
 * @animation: (transfer full): The #GdkPixbufAnimation to use
 * @scale_factor: The scale factor of the animation. Pass 0 to use
 *   the scale factor of @image_view
 *
 * Takes the given #GdkPixbufAnimation and sets the internal image to that
 * animation. This will also automatically start the animation. If you want
 * to unset the internal image data, look at gtk_image_view_set_surface().
 *
 */
void
gtk_image_view_set_animation (GtkImageView       *image_view,
							  GdkPixbufAnimation *animation,
							  int                 scale_factor)
{
  g_return_if_fail (GTK_IS_IMAGE_VIEW (image_view));
  g_return_if_fail (GDK_IS_PIXBUF_ANIMATION (animation));
  g_return_if_fail (scale_factor >= 0);

  gtk_image_view_replace_animation (image_view, animation, scale_factor);
}
