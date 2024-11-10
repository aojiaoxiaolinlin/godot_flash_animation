# Godot Flash Animation

The plugin can bring Flash animations into Godot.

## Feature

- [x] Support for importing Flash animations and Blend Render.
- [x] Multi Animation.  (Require follow certain rules, refer to the conversion tool.)
- [ ] Filter Render.

## Demo

![demo](./assets/images/8e68e59cf2e75b17a067c9f0eda1505a.png)

## Usage

1. Use
    Download the Flash conversion tool from the following link:  
   [Swf Tool](https://github.com/aojiaoxiaolinlin/swf_animation)

    Use a packing tool that can save file names. I have only tested with **Texture Packer**.

    After importing both this plugin and the packing tool plugin, enable the plugins. Then, create a new **SwfAnimation** node, and attach the generated `*.json` animation file resource to the node's **Animation Data** property.
