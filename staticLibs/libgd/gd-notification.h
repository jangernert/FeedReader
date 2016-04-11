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

#ifndef _GD_NOTIFICATION_H_
#define _GD_NOTIFICATION_H_

#include <gtk/gtk.h>

G_BEGIN_DECLS

#define GD_TYPE_NOTIFICATION             (gd_notification_get_type ())
#define GD_NOTIFICATION(obj)             (G_TYPE_CHECK_INSTANCE_CAST ((obj), GD_TYPE_NOTIFICATION, GdNotification))
#define GD_NOTIFICATION_CLASS(klass)     (G_TYPE_CHECK_CLASS_CAST ((klass), GD_TYPE_NOTIFICATION, GdNotificationClass))
#define GTK_IS_NOTIFICATION(obj)          (G_TYPE_CHECK_INSTANCE_TYPE ((obj), GD_TYPE_NOTIFICATION))
#define GTK_IS_NOTIFICATION_CLASS(klass)  (G_TYPE_CHECK_CLASS_TYPE ((klass), GD_TYPE_NOTIFICATION))
#define GD_NOTIFICATION_GET_CLASS(obj)   (G_TYPE_INSTANCE_GET_CLASS ((obj), GD_TYPE_NOTIFICATION, GdNotificationClass))

typedef struct _GdNotificationPrivate GdNotificationPrivate;
typedef struct _GdNotificationClass GdNotificationClass;
typedef struct _GdNotification GdNotification;

struct _GdNotificationClass {
  GtkBinClass parent_class;

  /* Signals */
  void (*dismissed) (GdNotification *self);
};

struct _GdNotification {
  GtkBin parent_instance;

  /*< private > */
  GdNotificationPrivate *priv;
};

GType gd_notification_get_type (void) G_GNUC_CONST;

GtkWidget *gd_notification_new         (void);
void       gd_notification_set_timeout (GdNotification *notification,
                                        gint            timeout_sec);
void       gd_notification_dismiss     (GdNotification *notification);
void       gd_notification_set_show_close_button (GdNotification *notification,
                                                  gboolean show_close_button);

G_END_DECLS

#endif /* _GD_NOTIFICATION_H_ */
