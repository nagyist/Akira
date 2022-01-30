/*
* Copyright (c) 2021 Alecaddd (http://alecaddd.com)
*
* This file is part of Akira.
*
* Akira is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.

* Akira is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.

* You should have received a copy of the GNU General Public License
* along with Akira. If not, see <https://www.gnu.org/licenses/>.
*
* Authored by: Giacomo "giacomoalbe" Alberini <giacomoalbe@gmail.com>
*/

public class Akira.Layouts.Sidebars.OptionsSidebar : Gtk.Grid {
    public unowned Lib.ViewCanvas view_canvas { get; construct; }

    public bool toggled {
        get {
            return visible;
        } set {
            visible = value;
            no_show_all = !value;
        }
    }

    public OptionsSidebar (Lib.ViewCanvas view_canvas) {
        Object (
            view_canvas: view_canvas
        );
    }

    construct {
        get_style_context ().add_class ("sidebar-l");

        var align_items_panel = new Layouts.Alignment.AlignmentPanel (view_canvas);
        attach (align_items_panel, 0, 0, 1, 1);


        var scrolled_grid = new Gtk.Grid () {
            expand = true
        };
        scrolled_grid.attach (new Akira.Layouts.Transforms.TransformPanel (view_canvas), 0, 0, 1, 1);

        var scrolled_window = new Gtk.ScrolledWindow (null, null) {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            expand = true
        };
        scrolled_window.add (scrolled_grid);
        attach (scrolled_window, 0, 1, 1, 1);

        /*
        var border_radius_panel = new Akira.Layouts.Partials.BorderRadiusPanel (window);
        fills_panel = new Akira.Layouts.Partials.FillsPanel (window);
        borders_panel = new Akira.Layouts.Partials.BordersPanel (window);
        scrolled_grid.attach (border_radius_panel, 0, 1, 1, 1);
        scrolled_grid.attach (fills_panel, 0, 2, 1, 1);
        scrolled_grid.attach (borders_panel, 0, 3, 1, 1);
        */

        // Connect signals.
        view_canvas.window.event_bus.toggle_presentation_mode.connect (toggle);
    }

    private void toggle () {
        toggled = !toggled;
    }
}
