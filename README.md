![rcw_caption](https://github.com/user-attachments/assets/a55caf4d-b62a-43b5-b217-d67235e5bba2)

# Robotic Complex Workspace

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) [![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FMalkarovPark%2FIndustrialKit%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/MalkarovPark/IndustrialKit) [![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FMalkarovPark%2FIndustrialKit%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/MalkarovPark/IndustrialKit)
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
* [Handling Statistics](#handling-statistics)
* [Connecting Objects](#connecting-objects)
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
   <img width="1087" src="https://github.com/user-attachments/assets/d6362a93-a51e-4550-83f6-17e7be218141" />
</p>

### Tools <a name="tools">

When creating, the *name* of the tool and its *model* are specified. Likewise robot, the *model* defines a model controller and direct connector.

<p align="center">
   <img width="1087" src="https://github.com/user-attachments/assets/91206811-3478-4803-831d-ddce69c8c2ed" />
</p>

### Parts <a name="parts">

When creating a part, its *name* and *model* are specified.

<p align="center">
   <img width="1087" src="https://github.com/user-attachments/assets/eb95f4a9-678c-49ef-88cc-4b3c3a125e9d" />
</p>

# Visual Modeling & Physical Simulation<a name="visual-modeling">

Provided through the SceneKit framework.

The functionality of building visual models is available for production equipment – robots and tools, both individually and as part of a complex.

Physical simulation allows you to evaluate the performance of technological operations by equipment on parts.

Can be endabled/disabled in settings if needed.

# Handling Statistics <a name="handling-statistics">

The application is available to receive statistical data from selected devices and save them in a document.
The statistics data are available in the form of various types of charts and disclosure groups of parameters.

<p align="center">
   <img width="1087" src="https://github.com/user-attachments/assets/751a9ca6-6722-4356-9c42-0b81f4203803" />
</p>

To open the statistics view, press the "<img width="12" src="https://github.com/user-attachments/assets/a9554ac8-45a8-4778-aaef-f0f167aa03d3" />" button next to the object of interest.

# Connecting Objects <a name="connecting-objects">

Connection to real equipment through connectors. For each device, the connector setting is available by pressing the "<img width="12" src="https://github.com/user-attachments/assets/dbd7c728-5476-4846-b8e0-7471b189b150" />" button.

<p align="center">
   <img width="1087" src="https://github.com/user-attachments/assets/fe11df94-625c-4d4c-b2aa-4ff1c45c97bf" />
</p>

The connected device can control its visual model, allowing it to be tracked in real time. The user can combine real and virtual devices in one document.

# Extensibility <a name="extensibility">

You can add support for new models of industrial equipment and new functions for IMA using industrial modules. These modules can be either built into the RCWorkspace application or delivered as external packages.

The set of available modules is defined in the settings – here you can see the quantity for each type and their names when you hover over the number. To connect external modules, tap the "<img width="12" src="https://github.com/user-attachments/assets/d6da3890-90ff-44c6-86f3-2a641b062231" />" button and select the folder containing the external modules.

<p align="center">
   <img width="472" src="https://github.com/user-attachments/assets/1992dcee-8327-4783-8326-b4bf7ce988a0" />
</p>

The development and synthesis of new modules, including the ability to integrate their project into the RCWorkspace application, is available through the [Industrial Builder](https://github.com/MalkarovPark/Industrial_Builder/) environment.

# Getting Help <a name="getting-help"></a>
GitHub is our primary forum for RCWorkspace. Feel free to open up issues about questions, problems, or ideas.

# License <a name="license"></a>
This project is made available under the terms of a Apache 2.0 license. See the [LICENSE](LICENSE) file.
