/* -*- Mode: C; tab-width: 8; indent-tabs-mode: nil; c-basic-offset: 2 -*- */
/*
 * gd-notification
 * Based on gtk-notification from gnome-contacts:
 * http://git.gnome.org/browse/gnome-contacts/tree/src/gtk-notification.c?id=3.3.91
 *
 * Copyright (C) Erick Pérez Castellanos 2011 <erick.red@gmail.com>
 * Copyright (C) 2012 Red Hat, Inc.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published
 * by the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.";
 */

#include "gd-notification.h"

/**
 * SECTION:gdnotification
 * @short_description: Report notification messages to the user
 * @include: gtk/gtk.h
 * @see_also: #GtkStatusbar, #GtkMessageDialog, #GtkInfoBar
 *
 * #GdNotification is a widget made for showing notifications to
 * the user, allowing them to close the notification or wait for it
 * to time out.
 *
 * #GdNotification provides one signal (#GdNotification::dismissed), for when the notification
 * times out or is closed.
 *
 */

#define GTK_PARAM_READWRITE G_PARAM_READWRITE|G_PARAM_STATIC_NAME|G_PARAM_STATIC_NICK|G_PARAM_STATIC_BLURB
#define SHADOW_OFFSET_X 2
#define SHADOW_OFFSET_Y 3
#define ANIMATION_TIME 200 /* msec */
#define ANIMATION_STEP 40 /* msec */

enum {
  PROP_0,
  PROP_TIMEOUT,
  PROP_SHOW_CLOSE_BUTTON
};

struct _GdNotificationPrivate {
  GtkWidget *close_button;
  gboolean show_close_button;

  GdkWindow *bin_window;

  int animate_y; /* from 0 to allocation.height */
  gboolean waiting_for_viewable;
  gboolean revealed;
  gboolean dismissed;
  gboolean sent_dismissed;
  guint animate_timeout;

  gint timeout;
  guint timeout_source_id;
};

enum {
  DISMISSED,
  LAST_SIGNAL
};

static guint notification_signals[LAST_SIGNAL] = { 0 };

static gboolean gd_notification_draw                           (GtkWidget       *widget,
                                                                 cairo_t         *cr);
static void     gd_notification_get_preferred_width            (GtkWidget       *widget,
                                                                 gint            *minimum_size,
                                                                 gint            *natural_size);
static void     gd_notification_get_preferred_height_for_width (GtkWidget       *widget,
                                                                 gint             width,
                                                                 gint            *minimum_height,
                                                                 gint            *natural_height);
static void     gd_notification_get_preferred_height           (GtkWidget       *widget,
                                                                 gint            *minimum_size,
                                                                 gint            *natural_size);
static void     gd_notification_get_preferred_width_for_height (GtkWidget       *widget,
                                                                 gint             height,
                                                                 gint            *minimum_width,
                                                                 gint            *natural_width);
static void     gd_notification_size_allocate                  (GtkWidget       *widget,
                                                                 GtkAllocation   *allocation);
static gboolean gd_notification_timeout_cb                     (gpointer         user_data);
static void     gd_notification_show                           (GtkWidget       *widget);
static void     gd_notification_add                            (GtkContainer    *container,
                                                                 GtkWidget       *child);

/* signals handlers */
static void     gd_notification_close_button_clicked_cb        (GtkWidget       *widget,
                                                                 gpointer         user_data);

G_DEFINE_TYPE(GdNotification, gd_notification, GTK_TYPE_BIN);

static void
gd_notification_init (GdNotification *notification)
{
  GtkWidget *close_button_image;
  GtkStyleContext *context;
  GdNotificationPrivate *priv;

  context = gtk_widget_get_style_context (GTK_WIDGET (notification));
  gtk_style_context_add_class (context, GTK_STYLE_CLASS_FRAME);
  gtk_style_context_add_class (context, "app-notification");

  gtk_widget_set_halign (GTK_WIDGET (notification), GTK_ALIGN_CENTER);
  gtk_widget_set_valign (GTK_WIDGET (notification), GTK_ALIGN_START);

  gtk_widget_set_has_window (GTK_WIDGET (notification), TRUE);

  priv = notification->priv =
    G_TYPE_INSTANCE_GET_PRIVATE (notification,
                                 GD_TYPE_NOTIFICATION,
                                 GdNotificationPrivate);

  priv->animate_y = 0;
  priv->close_button = gtk_button_new ();
  gtk_widget_set_parent (priv->close_button, GTK_WIDGET (notification));
  gtk_widget_show (priv->close_button);
  g_object_set (priv->close_button,
                "relief", GTK_RELIEF_NONE,
                "focus-on-click", FALSE,
                NULL);
  g_signal_connect (priv->close_button,
                    "clicked",
                    G_CALLBACK (gd_notification_close_button_clicked_cb),
                    notification);
  close_button_image = gtk_image_new_from_icon_name ("window-close-symbolic", GTK_ICON_SIZE_BUTTON);
  gtk_button_set_image (GTK_BUTTON (notification->priv->close_button), close_button_image);

  priv->timeout_source_id = 0;
}

static void
gd_notification_finalize (GObject *object)
{
  GdNotification *notification;
  GdNotificationPrivate *priv;

  g_return_if_fail (GTK_IS_NOTIFICATION (object));

  notification = GD_NOTIFICATION (object);
  priv = notification->priv;

  if (priv->animate_timeout != 0)
    g_source_remove (priv->animate_timeout);

  if (priv->timeout_source_id != 0)
    g_source_remove (priv->timeout_source_id);

  G_OBJECT_CLASS (gd_notification_parent_class)->finalize (object);
}

static void
gd_notification_destroy (GtkWidget *widget)
{
  GdNotification *notification = GD_NOTIFICATION (widget);
  GdNotificationPrivate *priv = notification->priv;

  if (!priv->sent_dismissed)
    {
      g_signal_emit (notification, notification_signals[DISMISSED], 0);
      priv->sent_dismissed = TRUE;
    }

  if (priv->close_button)
    {
      gtk_widget_unparent (priv->close_button);
      priv->close_button = NULL;
    }

  GTK_WIDGET_CLASS (gd_notification_parent_class)->destroy (widget);
}

static void
gd_notification_realize (GtkWidget *widget)
{
  GdNotification *notification = GD_NOTIFICATION (widget);
  GdNotificationPrivate *priv = notification->priv;
  GtkBin *bin = GTK_BIN (widget);
  GtkAllocation allocation;
  GtkWidget *child;
  GdkWindow *window;
  GdkWindowAttr attributes;
  gint attributes_mask;

  gtk_widget_set_realized (widget, TRUE);

  gtk_widget_get_allocation (widget, &allocation);

  attributes.x = allocation.x;
  attributes.y = allocation.y;
  attributes.width = allocation.width;
  attributes.height = allocation.height;
  attributes.window_type = GDK_WINDOW_CHILD;
  attributes.wclass = GDK_INPUT_OUTPUT;
  attributes.visual = gtk_widget_get_visual (widget);

  attributes.event_mask = GDK_VISIBILITY_NOTIFY_MASK | GDK_EXPOSURE_MASK;

  attributes_mask = GDK_WA_X | GDK_WA_Y | GDK_WA_VISUAL;

  window = gdk_window_new (gtk_widget_get_parent_window (widget),
                           &attributes, attributes_mask);
  gtk_widget_set_window (widget, window);
  gtk_widget_register_window (widget, window);

  attributes.x = 0;
  attributes.y = attributes.height + priv->animate_y;
  attributes.event_mask = gtk_widget_get_events (widget) |
                          GDK_EXPOSURE_MASK |
                          GDK_VISIBILITY_NOTIFY_MASK |
                          GDK_ENTER_NOTIFY_MASK |
                          GDK_LEAVE_NOTIFY_MASK;

  priv->bin_window = gdk_window_new (window, &attributes, attributes_mask);
  gtk_widget_register_window (widget, priv->bin_window);

  child = gtk_bin_get_child (bin);
  if (child)
    gtk_widget_set_parent_window (child, priv->bin_window);
  gtk_widget_set_parent_window (priv->close_button, priv->bin_window);

  gdk_window_show (priv->bin_window);
}

static void
gd_notification_unrealize (GtkWidget *widget)
{
  GdNotification *notification = GD_NOTIFICATION (widget);
  GdNotificationPrivate *priv = notification->priv;

  gtk_widget_unregister_window (widget, priv->bin_window);
  gdk_window_destroy (priv->bin_window);
  priv->bin_window = NULL;

  GTK_WIDGET_CLASS (gd_notification_parent_class)->unrealize (widget);
}

static int
animation_target (GdNotification *notification)
{
  GdNotificationPrivate *priv = notification->priv;
  GtkAllocation allocation;

  if (priv->revealed) {
    gtk_widget_get_allocation (GTK_WIDGET (notification), &allocation);
    return allocation.height;
  } else {
    return 0;
  }
}

static gboolean
animation_timeout_cb (gpointer user_data)
{
  GdNotification *notification = GD_NOTIFICATION (user_data);
  GdNotificationPrivate *priv = notification->priv;
  GtkAllocation allocation;
  int target, delta;

  target = animation_target (notification);

  if (priv->animate_y != target) {
    gtk_widget_get_allocation (GTK_WIDGET (notification), &allocation);

    delta = allocation.height * ANIMATION_STEP / ANIMATION_TIME;

    if (priv->revealed)
      priv->animate_y += delta;
    else
      priv->animate_y -= delta;

    priv->animate_y = CLAMP (priv->animate_y, 0, allocation.height);

    if (priv->bin_window != NULL)
      gdk_window_move (priv->bin_window,
                       0,
                       -allocation.height + priv->animate_y);
    return G_SOURCE_CONTINUE;
  }

  if (priv->dismissed && priv->animate_y == 0)
    gtk_widget_destroy (GTK_WIDGET (notification));

  priv->animate_timeout = 0;
  return G_SOURCE_REMOVE;
}

static void
start_animation (GdNotification *notification)
{
  GdNotificationPrivate *priv = notification->priv;
  int target;

  if (priv->animate_timeout != 0)
    return; /* Already running */

  target = animation_target (notification);
  if (priv->animate_y != target)
    notification->priv->animate_timeout =
      gdk_threads_add_timeout (ANIMATION_STEP,
                               animation_timeout_cb,
                               notification);
}

static void
gd_notification_show (GtkWidget *widget)
{
  GdNotification *notification = GD_NOTIFICATION (widget);
  GdNotificationPrivate *priv = notification->priv;

  GTK_WIDGET_CLASS (gd_notification_parent_class)->show (widget);
  priv->revealed = TRUE;
  priv->waiting_for_viewable = TRUE;
}

static void
gd_notification_hide (GtkWidget *widget)
{
  GdNotification *notification = GD_NOTIFICATION (widget);
  GdNotificationPrivate *priv = notification->priv;

  GTK_WIDGET_CLASS (gd_notification_parent_class)->hide (widget);
  priv->revealed = FALSE;
  priv->waiting_for_viewable = FALSE;
}

static void
gd_notification_set_property (GObject *object, guint prop_id, const GValue *value, GParamSpec *pspec)
{
  GdNotification *notification = GD_NOTIFICATION (object);

  g_return_if_fail (GTK_IS_NOTIFICATION (object));

  switch (prop_id) {
  case PROP_TIMEOUT:
    gd_notification_set_timeout (notification,
                                 g_value_get_int (value));
    break;
  case PROP_SHOW_CLOSE_BUTTON:
    gd_notification_set_show_close_button (notification,
                                           g_value_get_boolean (value));
    break;
  default:
    G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
    break;
  }
}

static void
gd_notification_get_property (GObject *object, guint prop_id, GValue *value, GParamSpec *pspec)
{
  g_return_if_fail (GTK_IS_NOTIFICATION (object));
  GdNotification *notification = GD_NOTIFICATION (object);

  switch (prop_id) {
  case PROP_TIMEOUT:
    g_value_set_int (value, notification->priv->timeout);
    break;
  case PROP_SHOW_CLOSE_BUTTON:
    g_value_set_boolean (value,
                         notification->priv->show_close_button);
    break;
  default:
    G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
    break;
  }
}

static void
gd_notification_forall (GtkContainer *container,
                         gboolean      include_internals,
                         GtkCallback   callback,
                         gpointer      callback_data)
{
  GtkBin *bin = GTK_BIN (container);
  GdNotification *notification = GD_NOTIFICATION (container);
  GdNotificationPrivate *priv = notification->priv;
  GtkWidget *child;

  child = gtk_bin_get_child (bin);
  if (child)
    (* callback) (child, callback_data);

  if (include_internals)
    (* callback) (priv->close_button, callback_data);
}

static void
unqueue_autohide (GdNotification *notification)
{
  GdNotificationPrivate *priv = notification->priv;

  if (priv->timeout_source_id)
    {
      g_source_remove (priv->timeout_source_id);
      priv->timeout_source_id = 0;
    }
}

static void
queue_autohide (GdNotification *notification)
{
  GdNotificationPrivate *priv = notification->priv;

  if (priv->timeout_source_id == 0 &&
      priv->timeout != -1)
    priv->timeout_source_id =
      gdk_threads_add_timeout (priv->timeout * 1000,
                               gd_notification_timeout_cb,
                               notification);
}

static gboolean
gd_notification_visibility_notify_event (GtkWidget          *widget,
                                          GdkEventVisibility  *event)
{
  GdNotification *notification = GD_NOTIFICATION (widget);
  GdNotificationPrivate *priv = notification->priv;

  if (!gtk_widget_get_visible (widget))
    return FALSE;

  if (priv->waiting_for_viewable)
    {
      start_animation (notification);
      priv->waiting_for_viewable = FALSE;
    }

  queue_autohide (notification);

  return FALSE;
}

static gboolean
gd_notification_enter_notify (GtkWidget        *widget,
                              GdkEventCrossing *event)
{
  GdNotification *notification = GD_NOTIFICATION (widget);
  GdNotificationPrivate *priv = notification->priv;

  if ((event->window == priv->bin_window) &&
      (event->detail != GDK_NOTIFY_INFERIOR))
    {
      unqueue_autohide (notification);
    }

  return FALSE;
}

static gboolean
gd_notification_leave_notify (GtkWidget        *widget,
                              GdkEventCrossing *event)
{
  GdNotification *notification = GD_NOTIFICATION (widget);
  GdNotificationPrivate *priv = notification->priv;

  if ((event->window == priv->bin_window) &&
      (event->detail != GDK_NOTIFY_INFERIOR))
    {
      queue_autohide (notification);
    }

  return FALSE;
}

static void
gd_notification_class_init (GdNotificationClass *klass)
{
  GObjectClass* object_class = G_OBJECT_CLASS (klass);
  GtkWidgetClass* widget_class = GTK_WIDGET_CLASS(klass);
  GtkContainerClass *container_class = GTK_CONTAINER_CLASS (klass);

  object_class->finalize = gd_notification_finalize;
  object_class->set_property = gd_notification_set_property;
  object_class->get_property = gd_notification_get_property;

  widget_class->show = gd_notification_show;
  widget_class->hide = gd_notification_hide;
  widget_class->destroy = gd_notification_destroy;
  widget_class->get_preferred_width = gd_notification_get_preferred_width;
  widget_class->get_preferred_height_for_width = gd_notification_get_preferred_height_for_width;
  widget_class->get_preferred_height = gd_notification_get_preferred_height;
  widget_class->get_preferred_width_for_height = gd_notification_get_preferred_width_for_height;
  widget_class->size_allocate = gd_notification_size_allocate;
  widget_class->draw = gd_notification_draw;
  widget_class->realize = gd_notification_realize;
  widget_class->unrealize = gd_notification_unrealize;
  widget_class->visibility_notify_event = gd_notification_visibility_notify_event;
  widget_class->enter_notify_event = gd_notification_enter_notify;
  widget_class->leave_notify_event = gd_notification_leave_notify;

  container_class->add = gd_notification_add;
  container_class->forall = gd_notification_forall;
  gtk_container_class_handle_border_width (container_class);


  /**
   * GdNotification:timeout:
   *
   * The time it takes to hide the widget, in seconds.
   *
   * Since: 0.1
   */
  g_object_class_install_property (object_class,
                                   PROP_TIMEOUT,
                                   g_param_spec_int("timeout", "timeout",
                                                    "The time it takes to hide the widget, in seconds",
                                                    -1, G_MAXINT, -1,
                                                    GTK_PARAM_READWRITE | G_PARAM_CONSTRUCT));
  g_object_class_install_property (object_class,
                                   PROP_SHOW_CLOSE_BUTTON,
                                   g_param_spec_boolean("show-close-button", "show-close-button",
                                                        "Whether to show a stock close button that dismisses the notification",
                                                        TRUE,
                                                        GTK_PARAM_READWRITE | G_PARAM_CONSTRUCT));

  notification_signals[DISMISSED] = g_signal_new ("dismissed",
                                                  G_OBJECT_CLASS_TYPE (klass),
                                                  G_SIGNAL_RUN_LAST,
                                                  G_STRUCT_OFFSET (GdNotificationClass, dismissed),
                                                  NULL,
                                                  NULL,
                                                  g_cclosure_marshal_VOID__VOID,
                                                  G_TYPE_NONE,
                                                  0);

  g_type_class_add_private (object_class, sizeof (GdNotificationPrivate));
}

static void
get_padding_and_border (GdNotification *notification,
                        GtkBorder *border)
{
  GtkStyleContext *context;
  GtkStateFlags state;
  GtkBorder tmp;

  context = gtk_widget_get_style_context (GTK_WIDGET (notification));
  state = gtk_widget_get_state_flags (GTK_WIDGET (notification));

  gtk_style_context_get_padding (context, state, border);

  gtk_style_context_get_border (context, state, &tmp);
  border->top += tmp.top;
  border->right += tmp.right;
  border->bottom += tmp.bottom;
  border->left += tmp.left;
}

static gboolean
gd_notification_draw (GtkWidget *widget, cairo_t *cr)
{
  GdNotification *notification = GD_NOTIFICATION (widget);
  GdNotificationPrivate *priv = notification->priv;
  GtkStyleContext *context;

  if (gtk_cairo_should_draw_window (cr, priv->bin_window))
    {
      context = gtk_widget_get_style_context (widget);

      gtk_render_background (context,  cr,
                             0, 0,
                             gtk_widget_get_allocated_width (widget),
                             gtk_widget_get_allocated_height (widget));
      gtk_render_frame (context,cr,
                        0, 0,
                        gtk_widget_get_allocated_width (widget),
                        gtk_widget_get_allocated_height (widget));


      if (GTK_WIDGET_CLASS (gd_notification_parent_class)->draw)
        GTK_WIDGET_CLASS (gd_notification_parent_class)->draw(widget, cr);
    }

  return FALSE;
}

static void
gd_notification_add (GtkContainer *container,
                      GtkWidget    *child)
{
  GtkBin *bin = GTK_BIN (container);
  GdNotification *notification = GD_NOTIFICATION (bin);
  GdNotificationPrivate *priv = notification->priv;

  g_return_if_fail (gtk_bin_get_child (bin) == NULL);

  gtk_widget_set_parent_window (child, priv->bin_window);

  GTK_CONTAINER_CLASS (gd_notification_parent_class)->add (container, child);
}


static void
gd_notification_get_preferred_width (GtkWidget *widget, gint *minimum_size, gint *natural_size)
{
  GdNotification *notification = GD_NOTIFICATION (widget);
  GdNotificationPrivate *priv = notification->priv;
  GtkBin *bin = GTK_BIN (widget);
  gint child_min, child_nat;
  GtkWidget *child;
  GtkBorder padding;
  gint minimum, natural;

  get_padding_and_border (notification, &padding);

  minimum = 0;
  natural = 0;

  child = gtk_bin_get_child (bin);
  if (child && gtk_widget_get_visible (child))
    {
      gtk_widget_get_preferred_width (child,
                                      &child_min, &child_nat);
      minimum += child_min;
      natural += child_nat;
    }

  if (priv->show_close_button)
    {
      gtk_widget_get_preferred_width (priv->close_button,
                                      &child_min, &child_nat);
      minimum += child_min;
      natural += child_nat;
    }

  minimum += padding.left + padding.right + 2 * SHADOW_OFFSET_X;
  natural += padding.left + padding.right + 2 * SHADOW_OFFSET_X;

 if (minimum_size)
    *minimum_size = minimum;

  if (natural_size)
    *natural_size = natural;
}

static void
gd_notification_get_preferred_width_for_height (GtkWidget *widget,
                                                 gint height,
                                                 gint *minimum_width,
                                                 gint *natural_width)
{
  GdNotification *notification = GD_NOTIFICATION (widget);
  GdNotificationPrivate *priv = notification->priv;
  GtkBin *bin = GTK_BIN (widget);
  gint child_min, child_nat, child_height;
  GtkWidget *child;
  GtkBorder padding;
  gint minimum, natural;

  get_padding_and_border (notification, &padding);

  minimum = 0;
  natural = 0;

  child_height = height - SHADOW_OFFSET_Y - padding.top - padding.bottom;

  child = gtk_bin_get_child (bin);
  if (child && gtk_widget_get_visible (child))
    {
      gtk_widget_get_preferred_width_for_height (child, child_height,
                                                 &child_min, &child_nat);
      minimum += child_min;
      natural += child_nat;
    }

  if (priv->show_close_button)
    {
      gtk_widget_get_preferred_width_for_height (priv->close_button, child_height,
                                                 &child_min, &child_nat);
      minimum += child_min;
      natural += child_nat;
    }

  minimum += padding.left + padding.right + 2 * SHADOW_OFFSET_X;
  natural += padding.left + padding.right + 2 * SHADOW_OFFSET_X;

 if (minimum_width)
    *minimum_width = minimum;

  if (natural_width)
    *natural_width = natural;
}

static void
gd_notification_get_preferred_height_for_width (GtkWidget *widget,
                                                 gint width,
                                                 gint *minimum_height,
                                                 gint *natural_height)
{
  GdNotification *notification = GD_NOTIFICATION (widget);
  GdNotificationPrivate *priv = notification->priv;
  GtkBin *bin = GTK_BIN (widget);
  gint child_min, child_nat, child_width, button_width = 0;
  GtkWidget *child;
  GtkBorder padding;
  gint minimum = 0, natural = 0;

  get_padding_and_border (notification, &padding);

  if (priv->show_close_button)
    {
      gtk_widget_get_preferred_height (priv->close_button,
                                       &minimum, &natural);
      gtk_widget_get_preferred_width (priv->close_button,
                                      NULL, &button_width);
    }

  child = gtk_bin_get_child (bin);
  if (child && gtk_widget_get_visible (child))
    {
      child_width = width - button_width -
        2 * SHADOW_OFFSET_X - padding.left - padding.right;

      gtk_widget_get_preferred_height_for_width (child, child_width,
                                                 &child_min, &child_nat);
      minimum = MAX (minimum, child_min);
      natural = MAX (natural, child_nat);
    }

  minimum += padding.top + padding.bottom + SHADOW_OFFSET_Y;
  natural += padding.top + padding.bottom + SHADOW_OFFSET_Y;

 if (minimum_height)
    *minimum_height = minimum;

  if (natural_height)
    *natural_height = natural;
}

static void
gd_notification_get_preferred_height (GtkWidget *widget, 
                                      gint *minimum_height, 
                                      gint *natural_height)
{
  gint width;

  gd_notification_get_preferred_width (widget, &width, NULL);
  gd_notification_get_preferred_height_for_width (widget, width,
                                                  minimum_height, natural_height);
}

static void
gd_notification_size_allocate (GtkWidget *widget,
                                GtkAllocation *allocation)
{
  GdNotification *notification = GD_NOTIFICATION (widget);
  GdNotificationPrivate *priv = notification->priv;
  GtkBin *bin = GTK_BIN (widget);
  GtkAllocation child_allocation;
  GtkBorder padding;
  GtkRequisition button_req;
  GtkWidget *child;

  gtk_widget_set_allocation (widget, allocation);

  /* If somehow the notification changes while not hidden
     and we're not animating, immediately follow the resize */
  if (priv->animate_y > 0 &&
      !priv->animate_timeout)
    priv->animate_y = allocation->height;

  get_padding_and_border (notification, &padding);

  if (gtk_widget_get_realized (widget))
    {
      gdk_window_move_resize (gtk_widget_get_window (widget),
                              allocation->x,
                              allocation->y,
                              allocation->width,
                              allocation->height);
      gdk_window_move_resize (priv->bin_window,
                              0,
                              -allocation->height + priv->animate_y,
                              allocation->width,
                              allocation->height);
    }

  child_allocation.x = SHADOW_OFFSET_X + padding.left;
  child_allocation.y = padding.top;

  if (priv->show_close_button)
    gtk_widget_get_preferred_size (priv->close_button, &button_req, NULL);
  else
    button_req.width = button_req.height = 0;

  child_allocation.height = MAX (1, allocation->height - SHADOW_OFFSET_Y - padding.top - padding.bottom);
  child_allocation.width = MAX (1, (allocation->width - button_req.width -
                                    2 * SHADOW_OFFSET_X - padding.left - padding.right));

  child = gtk_bin_get_child (bin);
  if (child && gtk_widget_get_visible (child))
    gtk_widget_size_allocate (child, &child_allocation);

  if (priv->show_close_button)
    {
      child_allocation.x += child_allocation.width;
      child_allocation.width = button_req.width;
      child_allocation.y += (child_allocation.height - button_req.height) / 2;
      child_allocation.height = button_req.height;

      gtk_widget_size_allocate (priv->close_button, &child_allocation);
    }
}

static gboolean
gd_notification_timeout_cb (gpointer user_data)
{
  GdNotification *notification = GD_NOTIFICATION (user_data);

  gd_notification_dismiss (notification);

  return G_SOURCE_REMOVE;
}

void
gd_notification_set_timeout (GdNotification *notification,
                             gint            timeout_sec)
{
  GdNotificationPrivate *priv = notification->priv;

  priv->timeout = timeout_sec;
  g_object_notify (G_OBJECT (notification), "timeout");
}

void
gd_notification_set_show_close_button (GdNotification *notification,
                                       gboolean show_close_button)
{
  GdNotificationPrivate *priv = notification->priv;

  priv->show_close_button = show_close_button;

  gtk_widget_set_visible (priv->close_button, show_close_button);
  gtk_widget_queue_resize (GTK_WIDGET (notification));
}

void
gd_notification_dismiss (GdNotification *notification)
{
  GdNotificationPrivate *priv = notification->priv;

  unqueue_autohide (notification);

  priv->dismissed = TRUE;
  priv->revealed = FALSE;
  start_animation (notification);
}

static void
gd_notification_close_button_clicked_cb (GtkWidget *widget, gpointer user_data)
{
  GdNotification *notification = GD_NOTIFICATION(user_data);

  gd_notification_dismiss (notification);
}

GtkWidget *
gd_notification_new (void)
{
  return g_object_new (GD_TYPE_NOTIFICATION, NULL);
}
