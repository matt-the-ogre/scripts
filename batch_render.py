import bpy
import os
import sys
import math

def set_camera_to_fit_object(camera, obj, angle):
    # Calculate bounding box dimensions
    bbox_center = obj.location
    dimensions = obj.dimensions
    max_dimension = max(dimensions)

    # Position the camera to fit the object
    distance = max_dimension * 2.5  # Scale multiplier to ensure framing

    if angle == "front":
        camera.location = (0, -distance, bbox_center.z)
    elif angle == "side":
        camera.location = (-distance, 0, bbox_center.z)
    elif angle == "top":
        camera.location = (0, 0, bbox_center.z + distance)
    elif angle == "front_side_top":
        camera.location = (-distance * 0.7, -distance * 0.7, bbox_center.z + distance * 0.5)

    camera.data.lens = 50  # Set focal length for perspective

    # Point the camera at the object's origin
    direction = (bbox_center - camera.location).normalized()
    quat = direction.to_track_quat('-Z', 'Y')
    camera.rotation_euler = quat.to_euler()

def setup_lighting():
    # Clear existing lights
    for light in [obj for obj in bpy.data.objects if obj.type == 'LIGHT']:
        bpy.data.objects.remove(light, do_unlink=True)

    # Add key light
    key_light = bpy.data.objects.new("KeyLight", bpy.data.lights.new("KeyLight", 'AREA'))
    key_light.location = (5, -5, 5)
    key_light.data.energy = 1000
    bpy.context.scene.collection.objects.link(key_light)

    # Add fill light
    fill_light = bpy.data.objects.new("FillLight", bpy.data.lights.new("FillLight", 'AREA'))
    fill_light.location = (-5, -5, 2)
    fill_light.data.energy = 300
    bpy.context.scene.collection.objects.link(fill_light)

    # Add back light
    back_light = bpy.data.objects.new("BackLight", bpy.data.lights.new("BackLight", 'AREA'))
    back_light.location = (0, 5, 5)
    back_light.data.energy = 500
    bpy.context.scene.collection.objects.link(back_light)

def render_stl(file_path, output_dir):
    # Ensure STL importer is available
    import_mesh_stl = bpy.ops.import_mesh.stl
    if not import_mesh_stl.poll():
        print(f"STL Import operator not available for file: {file_path}")
        return

    filename = os.path.splitext(os.path.basename(file_path))[0]
    angles = {
        "front": "front",
        "side": "side",
        "top": "top",
        "front_side_top": "front_side_top"
    }

    # Clear the scene
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete()

    # Import the STL file
    import_mesh_stl(filepath=file_path)
    obj = bpy.context.selected_objects[0]

    # Set up camera and lighting
    camera = bpy.data.objects.new("Camera", bpy.data.cameras.new("Camera"))
    bpy.context.scene.collection.objects.link(camera)
    bpy.context.scene.camera = camera

    # Set up improved lighting
    setup_lighting()

    # Set render settings
    bpy.context.scene.render.engine = 'CYCLES'
    bpy.context.scene.render.image_settings.file_format = 'PNG'
    bpy.context.scene.render.image_settings.color_mode = 'RGBA'
    bpy.context.scene.render.resolution_x = 1024
    bpy.context.scene.render.resolution_y = 1024

    # Render from different angles
    for angle_name, angle in angles.items():
        set_camera_to_fit_object(camera, obj, angle)

        # Center the object
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.origin_set(type='ORIGIN_CENTER_OF_MASS', center='BOUNDS')
        bpy.ops.object.location_clear()

        # Set output path
        output_path = os.path.join(output_dir, f"{filename}_{angle_name}.png")
        bpy.context.scene.render.filepath = output_path

        # Render
        bpy.ops.render.render(write_still=True)

if __name__ == "__main__":
    # Ensure STL add-on is enabled
    addon_name = "io_mesh_stl"
    if addon_name not in bpy.context.preferences.addons:
        bpy.ops.preferences.addon_enable(module=addon_name)

    # Get command line arguments
    args = sys.argv[sys.argv.index("--") + 1:]
    input_dir = args[0]
    output_dir = args[1]

    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    # Process all STL files in the input directory
    for file_name in os.listdir(input_dir):
        if file_name.lower().endswith(".stl"):
            file_path = os.path.join(input_dir, file_name)
            render_stl(file_path, output_dir)
