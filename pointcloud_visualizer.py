#!/usr/bin/env python3
"""
OAK-D Pro Point Cloud Visualizer
Creates a colorful 3D point cloud from the depth stream with enhanced color mapping
"""

import cv2
import numpy as np
import socket
import struct
import threading
import time
import open3d as o3d
import sys

class PointCloudVisualizer:
    def __init__(self, host="192.168.1.201", depth_port=5003):
        self.host = host
        self.depth_port = depth_port

        # Camera parameters for point cloud generation
        self.depth_width = 640
        self.depth_height = 360

        # Camera intrinsics (estimated for depth resolution)
        self.fx = 400.0
        self.fy = 400.0
        self.cx = 320.0
        self.cy = 180.0

        # Current frame
        self.depth_frame = None
        self.frame_lock = threading.Lock()
        self.running = False

        # Open3D visualization
        self.vis = None
        self.pcd = o3d.geometry.PointCloud()

        # Performance tracking
        self.frame_count = 0
        self.last_fps_time = time.time()

    def receive_depth_stream(self):
        """Receive depth frames using the original protocol"""
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.connect((self.host, self.depth_port))
            print(f"Connected to depth stream at {self.host}:{self.depth_port}")

            while self.running:
                try:
                    # Receive frame size (4 bytes, big-endian)
                    frame_size_data = sock.recv(4)
                    if len(frame_size_data) != 4:
                        break
                    frame_size = struct.unpack('>I', frame_size_data)[0]

                    # Receive frame data
                    frame_data = b''
                    while len(frame_data) < frame_size:
                        chunk = sock.recv(frame_size - len(frame_data))
                        if not chunk:
                            break
                        frame_data += chunk

                    if len(frame_data) == frame_size:
                        # Decode JPEG as grayscale depth
                        img_array = np.frombuffer(frame_data, dtype=np.uint8)
                        depth_frame = cv2.imdecode(img_array, cv2.IMREAD_GRAYSCALE)

                        if depth_frame is not None:
                            with self.frame_lock:
                                self.depth_frame = depth_frame

                except Exception as e:
                    continue

            sock.close()
        except Exception as e:
            print(f"Depth stream error: {e}")

    def create_colorful_point_cloud(self, depth_image):
        """Create point cloud with enhanced HSV coloring based on depth and surface features"""
        depth_height, depth_width = depth_image.shape

        # Create coordinate meshgrid
        xx, yy = np.meshgrid(np.arange(depth_width), np.arange(depth_height))

        # Convert normalized depth values to distance
        depth_normalized = depth_image.astype(np.float32) / 255.0

        # Map to distance range
        min_distance = 0.5
        max_distance = 5.0
        z = max_distance - (depth_normalized * (max_distance - min_distance))

        # Filter valid depth values
        valid_mask = depth_image > 15

        # Calculate 3D coordinates
        x = (xx - self.cx) * z / self.fx
        y = (yy - self.cy) * z / self.fy

        # Get valid points
        points = np.stack([x, y, z], axis=-1)[valid_mask]

        # Enhanced color mapping
        colors = np.zeros((len(points), 3))

        if len(points) > 0:
            # Get depth values for coloring
            depth_values = depth_normalized[valid_mask]

            # Calculate surface gradients for texture
            grad_x = cv2.Sobel(depth_image, cv2.CV_64F, 1, 0, ksize=3)
            grad_y = cv2.Sobel(depth_image, cv2.CV_64F, 0, 1, ksize=3)
            gradient_magnitude = np.sqrt(grad_x**2 + grad_y**2)
            gradient_norm = np.clip(gradient_magnitude / np.max(gradient_magnitude), 0, 1)
            gradient_values = gradient_norm[valid_mask]

            # Create vibrant color mapping
            for i, (depth_val, grad_val) in enumerate(zip(depth_values, gradient_values)):
                # Distance-based hue (blue=far, red=close)
                hue = (1.0 - depth_val) * 240  # 240 to 0 degrees (blue to red)

                # Surface complexity affects saturation
                saturation = 0.7 + 0.3 * grad_val

                # Brightness based on depth with edge enhancement
                value = 0.6 + 0.3 * (1.0 - depth_val) + 0.1 * grad_val

                # Convert HSV to RGB
                hsv_color = np.array([[[hue/2, saturation*255, value*255]]], dtype=np.uint8)
                rgb_color = cv2.cvtColor(hsv_color, cv2.COLOR_HSV2RGB)[0, 0]
                colors[i] = rgb_color / 255.0

        return points.reshape(-1, 3), colors.reshape(-1, 3)

    def run_visualization(self):
        """Main visualization loop"""
        # Create visualizer
        self.vis = o3d.visualization.Visualizer()
        self.vis.create_window(
            window_name="OAK-D Pro Point Cloud Visualizer",
            width=1280, height=720
        )

        # Add coordinate frame
        coord_frame = o3d.geometry.TriangleMesh.create_coordinate_frame(size=0.5)
        self.vis.add_geometry(coord_frame)

        # Add point cloud
        self.vis.add_geometry(self.pcd)

        # Set up camera view
        view_ctl = self.vis.get_view_control()
        view_ctl.set_zoom(0.6)

        # Configure render options
        render_option = self.vis.get_render_option()
        render_option.point_size = 3.0
        render_option.background_color = np.array([0.05, 0.05, 0.05])

        print("\nPoint Cloud Visualizer Controls:")
        print("  Left mouse: Rotate view")
        print("  Ctrl+Left: Pan view")
        print("  Mouse wheel: Zoom")
        print("  R: Reset view")
        print("  Q/Esc: Quit")
        print("\nColorful depth-based visualization active!")

        first_frame = True

        while self.running:
            with self.frame_lock:
                depth = self.depth_frame

            if depth is not None:
                try:
                    points, colors = self.create_colorful_point_cloud(depth)

                    if len(points) > 500:
                        self.pcd.points = o3d.utility.Vector3dVector(points)
                        self.pcd.colors = o3d.utility.Vector3dVector(colors)

                        # Estimate normals for better visualization
                        if len(points) > 100:
                            self.pcd.estimate_normals(
                                search_param=o3d.geometry.KDTreeSearchParamHybrid(
                                    radius=0.05, max_nn=30
                                )
                            )

                        if first_frame:
                            self.vis.reset_view_point(True)
                            first_frame = False

                        self.vis.update_geometry(self.pcd)

                        # FPS calculation
                        self.frame_count += 1
                        current_time = time.time()
                        if current_time - self.last_fps_time > 2.0:
                            fps = self.frame_count / (current_time - self.last_fps_time)
                            print(f"Point Cloud FPS: {fps:.1f} | Points: {len(points):,}")
                            self.frame_count = 0
                            self.last_fps_time = current_time

                except Exception as e:
                    print(f"Point cloud generation error: {e}")

            if not self.vis.poll_events():
                break
            self.vis.update_renderer()
            time.sleep(0.01)

        self.vis.destroy_window()

    def run(self):
        """Main entry point"""
        self.running = True

        # Start receiver thread
        depth_thread = threading.Thread(target=self.receive_depth_stream)
        depth_thread.start()

        # Give stream time to connect
        print("Waiting for depth stream to initialize...")
        time.sleep(3)

        try:
            self.run_visualization()
        except KeyboardInterrupt:
            print("\nStopping...")
        finally:
            self.running = False
            depth_thread.join(timeout=2)

def main():
    print("=" * 60)
    print("  OAK-D Pro Point Cloud Visualizer")
    print("=" * 60)
    print()
    print("Creates a colorful 3D point cloud from depth stream")
    print("Colors represent distance and surface features")
    print()

    visualizer = PointCloudVisualizer()
    visualizer.run()

if __name__ == "__main__":
    main()