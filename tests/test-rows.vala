/* Rows in the folder, message and thread lists are replaced whenever those
 * lists are rebuilt. A row that is still alive once it is out of its list is
 * memory that never comes back. Handlers are methods, as in the window: a
 * lambda that captured the row would fail this test. */

class RowWatch : Object {
    public bool finalized;

    public void on_finalized (Object row) {
        this.finalized = true;
    }

    public void on_click (Gtk.GestureClick click, int n, double x, double y) {
    }

    public void on_mark (Mail.MessageRow row) {
    }

    public void on_folder_context (Mail.FolderRow row, double x, double y) {
    }

    public void on_expander (Mail.FolderRow row) {
    }

    public void on_thread_context (Mail.ThreadRow row, double x, double y) {
    }
}

void check_freed (string what, owned Gtk.Widget row, Gtk.Widget list, RowWatch watch) {
    row.weak_ref (watch.on_finalized);
    if (list is Gtk.ListBox) {
        ((Gtk.ListBox) list).append (row);
        ((Gtk.ListBox) list).remove (row);
    } else {
        ((Gtk.Box) list).append (row);
        ((Gtk.Box) list).remove (row);
    }
    row = null;
    if (!watch.finalized)
        error ("a %s removed from its list is never freed", what);
    watch.finalized = false;
}

int main (string[] args) {
    if (!Gtk.init_check ()) {
        print ("rows: no display, row lifetime not checked\n");
        return 0;
    }

    var watch = new RowWatch ();
    var list = new Gtk.ListBox ();
    var folder = new Mail.Folder () {
        name = "Inbox",
        full_name = "INBOX",
        has_children = true,
    };
    var folder_row = new Mail.FolderRow (folder);
    folder_row.context_pressed.connect (watch.on_folder_context);
    folder_row.expander_toggled.connect (watch.on_expander);
    check_freed ("folder row", (owned) folder_row, list, watch);

    var message_row = new Mail.MessageRow ();
    message_row.mark_read_clicked.connect (watch.on_mark);
    var message_click = new Gtk.GestureClick () {
        button = Gdk.BUTTON_SECONDARY,
    };
    message_click.pressed.connect (watch.on_click);
    message_row.add_controller (message_click);
    check_freed ("message row", (owned) message_row, new Gtk.Box (Gtk.Orientation.VERTICAL, 0), watch);

    var thread_row = new Mail.ThreadRow (new Mail.Message () {
        uid = "1",
        from = "a@b.c",
    });
    thread_row.context_conversation = new Mail.Conversation ();
    thread_row.context_pressed.connect (watch.on_thread_context);
    var thread_click = new Gtk.GestureClick () {
        button = Gdk.BUTTON_PRIMARY,
    };
    thread_click.pressed.connect (watch.on_click);
    thread_row.add_controller (thread_click);
    check_freed ("thread row", (owned) thread_row, list, watch);
    return 0;
}
