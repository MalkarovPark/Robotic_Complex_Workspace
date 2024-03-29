![RCWorkspace](https://github.com/MalkarovPark/Robotic_Complex_Workspace/assets/62340924/0597a5a0-a6ae-40c5-9fcf-54a17d0dbb37)

# Robotic Complex Workspace

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) ![Swift](https://img.shields.io/badge/swift-5.9-brightgreen.svg) ![Xcode 15.0+](https://img.shields.io/badge/Xcode-15.0%2B-blue.svg) ![macOS 14.0+](https://img.shields.io/badge/macOS-14.0%2B-blue.svg) ![iOS 17.0+](https://img.shields.io/badge/iOS-17.0%2B-blue.svg) ![visionOS 1.0+](https://img.shields.io/badge/visionOS-1.0%2B-blue.svg)
<a href="https://celadon-production-systems.blogspot.com/2023/12/the-ithi-macro-assembler-ima-formalizes.html">
<img src="https://img.shields.io/badge/^__^-IMA-AB88FF"></a>
<a href="https://github.com/MalkarovPark/IndustrialKit">
<img src="https://img.shields.io/badge/-IndustrialKit-05A89D"></a>

Robotic Complex Workspace is an open source application for designing and controlling of automated means of production. The application provides a convinient approach both in modeling the production system and direct control of automatics.

# Table of Contents
* [Requirements](#requirements)
* [Getting Started](#getting-started)
    * [Application Installation](#application-installation)
    * [Project Edititing](#project-editing)
* [Working With Document](#working-with-document)
    * [Robots](#robots)
    * [Tools](#tools)
    * [Parts](#parts)
* [Visual Modeling](#visual-modeling)
* [Connecting Objects](#connecting-objects)
* [Handling Statistics](#handling-statistics)
* [Extensibility](#extensibility)
* [Getting Help](#getting-help)
* [License](#license)

# Requirements <a name="requirements"></a>

The application codebase supports macOS, iOS/iPadOS and requires Xcode 14.1 or newer. The Robotic Complex Workspace application has a Base SDK version of 13.0 and 16.1 respectively.

# Getting Started <a name="getting-started"></a>

* [Website](https://celadon-production-systems.carrd.co/)
* [Documentation](https://celadon-industrial.github.io/IndustrialKit/documentation/rcworkspace/)

### Application Installation <a name="application-installation"></a>

Download an image from the *releases* and use application package for the appropriate platform.

Connect the necessary property list files in the application settings for robots, tools and parts.

*macOS*

[Copy](https://support.apple.com/guide/mac-help/mh35835/mac) a package with the *app* extension to the Applications folder. [Confirm launch](https://support.apple.com/guide/mac-help/mh40616/mac).

*iOS & iPadOS*

Official installation method coming in the 17th versions of iOS and iPadOS. Or you may install application package by your own developer profile and special installers. Also possible to use the app in application playground format by the [Swift Playgrounds](https://apps.apple.com/us/app/swift-playgrounds/id908519492) (iPadOS only).

### Project Editing <a name="project-editing"></a>

You may view and edit this application project by two ways:
* Clone this repository;
* Download ZIP archive from this page.

Open downloaded project in the Xcode and confirm trust.

# Working With Document <a name="working-with-document"></a>

RCWorkspace is the document based app. Thus, each production complex is a separate document. You can create a new or open an existing document that has a *preset* extension.

Objects are created in the relevant items available through the sidebar. All created objects can be placed and positioned in the workspace.

### Robots <a name="robots">

When creating a robot, in addition to the *name*, the *manufacturer*, *series* and *model* are specified. The *model* parameter determines how the visual model is controlled and direct connector.

<p align="center">
  <img width="900" src="https://github.com/MalkarovPark/Robotic_Complex_Workspace/assets/62340924/6338ced4-8298-4adb-b9bf-e14cb421ee2c">
</p>

### Tools <a name="tools">

When creating, the *name* of the tool and its *model* are specified. Likewise robot, the *model* defines a model controller and direct connector.

<p align="center">
  <img width="743" src="https://github.com/MalkarovPark/Robotic_Complex_Workspace/assets/62340924/7bb0bebc-15b7-40a9-8312-c9eeeac17522">
</p>

### Parts <a name="parts">

When creating a part, its *name* and *model* are specified.

<p align="center">
  <img width="583" src="https://github.com/MalkarovPark/Robotic_Complex_Workspace/assets/62340924/c730d3a5-4c3a-45d6-b351-9d4c27ba35c2">
</p>

# Visual Modeling & Physical Simulation<a name="visual-modeling">

Provided through the SceneKit framework.

The functionality of building visual models is available for production equipment – robots and tools, both individually and as part of a complex.

Physical simulation allows you to evaluate the performance of technological operations by equipment on parts.

Can be endabled/disabled in settings if needed.

# Connecting Objects <a name="connecting-objects">

Connection to real equipment through connectors. For each device, the connector setting is available by pressing the ![link@8x](https://user-images.githubusercontent.com/62340924/230892411-66714a6a-f2e3-4415-a5f1-2d1e22d255ed.png) button.

<p align="center">
  <img width="423" src="https://github.com/MalkarovPark/Robotic_Complex_Workspace/assets/62340924/d0809203-ee20-4990-8233-c21f5621fc54">
</p>

The connected device can control its visual model, allowing it to be tracked in real time. The user can combine real and virtual devices in one document.

# Handling Statistics <a name="handling-statistics">

The application is available to receive statistical data from selected devices and save them in a document.
The statistics data are available in the form of various types of charts and disclosure groups of parameters.

<p align="center">
  <img width="583px" src="https://github.com/MalkarovPark/Robotic_Complex_Workspace/assets/62340924/6f0eb97b-c18a-47e7-aa19-79148008fc85" />
</p>

To open the statistics view, press the ![chart bar@8x](https://user-images.githubusercontent.com/62340924/230895161-665df98e-6fc5-426e-9a86-60b51d25b84e.png) button next to the object of interest.

# Extensibility <a name="extensibility">

You can add support for new models of industrial equipment or parts.

Create your controllers and connectors, new visual models. If you create your own fork – don't forget to add the models to the appropriate property list files – RobotsInfo, ToolsInfo, PartsInfo. To select the appropriate controller and connector classes, you need to update the passed *select_robot_modules* and *select_tool_modules functions* in the ContentView.

External model files and parametric files describing them (similar in structure to internal ones) can be connected in the application settings.

<p align="center">
  <img width="408" src="https://github.com/MalkarovPark/Robotic_Complex_Workspace/assets/62340924/946200c5-85b6-4ebc-8eb1-b41cb2c71bc7">
</p>

# Getting Help <a name="getting-help"></a>
GitHub is our primary forum for RCWorkspace. Feel free to open up issues about questions, problems, or ideas.

# License <a name="license"></a>
This project is made available under the terms of a Apache 2.0 license. See the [LICENSE](LICENSE) file.
