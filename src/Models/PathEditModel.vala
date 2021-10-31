/**
 * Copyright (c) 2021 Alecaddd (https://alecaddd.com)
 *
 * This file is part of Akira.
 *
 * Akira is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.

 * Akira is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with Akira. If not, see <https://www.gnu.org/licenses/>.
 *
 * Authored by: Ashish Shevale <shevaleashish@gmail.com>
*/

public class Akira.Models.PathEditModel : Object {

    public Lib.Items.ModelInstance instance { get; construct; }
    public unowned Lib.ViewCanvas view_canvas { get; construct; }

    private ViewLayers.ViewLayerPath path_layer;

    private Lib.Modes.PathEditMode.Type[] commands;
    private Geometry.Point[] points;

    public Geometry.Point first_point;
    private Geometry.Point[] live_pts;
    private int live_pts_len = -1;

    public PathEditModel (Lib.Items.ModelInstance instance, Lib.ViewCanvas view_canvas) {
        Object (
            view_canvas: view_canvas,
            instance: instance
        );

        first_point = Geometry.Point (-1, -1);

        commands = instance.components.path.commands;
        points = instance.components.path.data;

        // Layer to show when editing paths.
        path_layer = new ViewLayers.ViewLayerPath ();
        path_layer.add_to_canvas (ViewLayers.ViewLayer.PATH_LAYER_ID, view_canvas);

        update_view ();
    }

    public void add_live_points_to_path (Geometry.Point[] points, Lib.Modes.PathEditMode.Type live_command, int length) {
        commands.resize (commands.length + 1);
        commands[commands.length - 1] = live_command;

        for (int i = 0; i < length; ++i) {
            var new_pt = Geometry.Point (points[i].x - first_point.x, points[i].y - first_point.y);
            add_point_to_path (new_pt);
        }

        live_pts = new Geometry.Point[0];
        live_pts_len = 0;

        recompute_components ();
    }

    /*
     * This method shift all points in path such that none of them are in negative space.
     */
    private void add_point_to_path (Geometry.Point point, int index = -1) {
        // var old_path_points = instance.components.path.data;
        Geometry.Point[] new_path_points = new Geometry.Point[points.length + 1];

        index = (index == -1) ? index = points.length : index;

        for (int i = 0; i < index; ++i) {
            new_path_points[i] = points[i];
        }

        new_path_points[index] = point;

        for (int i = index + 1; i < points.length + 1; ++i) {
            new_path_points[i] = points[i - 1];
        }

        points = recalculate_points (new_path_points);
        instance.components.path = new Lib.Components.Path.from_points (points, commands);
    }

    public void set_live_points (Geometry.Point[] live_pts, int length) {
        this.live_pts = live_pts;
        this.live_pts_len = length;

        update_view ();
    }

    public Geometry.Point[] delete_last_point () {
        if (commands[commands.length - 1] == Lib.Modes.PathEditMode.Type.LINE) {
            commands.resize (commands.length - 1);
            points.resize (points.length - 1);

            points = recalculate_points (points);
            instance.components.path = new Lib.Components.Path.from_points (points, commands);
            recompute_components ();

            return new Geometry.Point[0];
        }

        var new_live_pts = new Geometry.Point[4];
        new_live_pts[2] = Geometry.Point (points[points.length - 2].x + first_point.x, points[points.length - 2].y + first_point.y);
        new_live_pts[1] = Geometry.Point (points[points.length - 3].x + first_point.x, points[points.length - 3].y + first_point.y);
        new_live_pts[0] = Geometry.Point (points[points.length - 4].x + first_point.x, points[points.length - 4].y + first_point.y);

        commands.resize (commands.length - 1);
        points.resize (points.length - 4);

        points = recalculate_points (points);
        instance.components.path = new Lib.Components.Path.from_points (points, commands);
        recompute_components ();

        return new_live_pts;
    }

    /*
     * This method is used to check if user clicked on a point in the path.
     * Returns true if clicked, false otherwise.
     * If a point was clicked, index refers to its location.
     */
    public bool hit_test (double x, double y, ref int index) {
        Geometry.Point point = Geometry.Point (x, y);

        for (int i = 0; i < points.length; ++i) {
            double delta_x = Math.ceil ((points[i].x + first_point.x - point.x).abs ());
            double delta_y = Math.ceil ((points[i].y + first_point.y - point.y).abs ());

            if (delta_x <= 2 && delta_y <= 2) {
                index = i;
                return true;
            }
        }

        return false;
    }

    /*
     * This method will be used when editing paths to update the position of a point.
     */
    public void modify_point_value (int idx, Geometry.Point new_pos) {
        new_pos.x -= first_point.x;
        new_pos.y -= first_point.y;

        points[idx] = new_pos;

        // After updating a point, we need to recalculate the first_point,
        // update the path, and do some other calculations
        points = recalculate_points (points);
        instance.components.path = new Lib.Components.Path.from_points (points, commands);
        recompute_components ();
    }

    /*
     * This method shift all points in path such that none of them are in negative space.
     */
    private Geometry.Point[] recalculate_points (Geometry.Point[] points) {
        double min_x = 100000, min_y = 100000;

        foreach (var pt in points) {
            if (pt.x < min_x) {
                min_x = pt.x;
            }
            if (pt.y < min_y) {
                min_y = pt.y;
            }
        }

        Geometry.Point[] recalculated_points = new Geometry.Point[points.length];

        // Shift all the points.
        for (int i = 0; i < points.length; ++i) {
            recalculated_points[i] = Geometry.Point (points[i].x - min_x, points[i].y - min_y);
        }

        // Then shift the reference point.
        first_point.x += min_x;
        first_point.y += min_y;

        return recalculated_points;
    }

    private void recompute_components () {
        // To calculate the new center of bounds of rectangle,
        // Move the center to point where user placed first point. This is represented as (0,0) internally.
        // Then translate it to the relative center of bounding box of path.
        var bounds = instance.components.path.calculate_extents ();
        double center_x = first_point.x + bounds.center_x;
        double center_y = first_point.y + bounds.center_y;

        instance.components.center = new Lib.Components.Coordinates (center_x, center_y);
        instance.components.size = new Lib.Components.Size (bounds.width, bounds.height, false);
        // Update the component.
        view_canvas.items_manager.item_model.mark_node_geometry_dirty_by_id (instance.id);
        view_canvas.items_manager.compile_model ();

        update_view ();
    }

    /*
     * Recalculates the extents and updates the ViewLayerPath
     */
    private void update_view () {
        var points = instance.components.path.data;

        var coordinates = view_canvas.selection_manager.selection.coordinates ();

        Geometry.Rectangle extents = Geometry.Rectangle.empty ();
        extents.left = coordinates.center_x - coordinates.width / 2.0;
        extents.right = coordinates.center_x + coordinates.width / 2.0;
        extents.top = coordinates.center_y - coordinates.height / 2.0;
        extents.bottom = coordinates.center_y + coordinates.height / 2.0;

        PathDataModel path_data = PathDataModel ();
        path_data.points = points;
        path_data.commands = commands;
        path_data.live_pts = live_pts;
        path_data.length = live_pts_len;
        path_data.extents = extents;
        path_data.rot_angle = instance.components.transform.rotation;

        path_data.live_extents = get_extents_using_live_pts (extents);

        path_layer.update_path_data (path_data);
    }

    private Geometry.Rectangle get_extents_using_live_pts (Geometry.Rectangle extents) {
        if (points.length == 0 || live_pts_len == -1) {
            return extents;
        }

        var data = new Geometry.Point[live_pts_len + 1];

        data[0] = Geometry.Point ();
        data[0].x = points[points.length - 1].x + first_point.x;
        data[0].y = points[points.length - 1].y + first_point.y;

        for (int i = 0; i < live_pts_len; ++i) {
            data[i + 1].x = live_pts[i].x;
            data[i + 1].y = live_pts[i].y;
        }

        // The array of commands isn't really needed for calculating extents. So just keep it empty.
        var cmds = new Lib.Modes.PathEditMode.Type[0];
        var live_path = new Lib.Components.Path.from_points (data, cmds);

        return live_path.calculate_extents ();
    }

}

public struct Akira.Models.PathDataModel {
    public Geometry.Point[] points;
    public Lib.Modes.PathEditMode.Type[] commands;

    public Geometry.Point[] live_pts;
    public int length;

    public Geometry.Rectangle extents;
    public Geometry.Rectangle live_extents;

    public double rot_angle;
}
