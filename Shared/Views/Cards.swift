//
//  Cards.swift
//  Robotic Complex Workspace
//
//  Created by Malkarov Park on 01.11.2022.
//

import SwiftUI

//MARK: - Large card view
struct LargeCardView: View
{
    @State var color: Color
    #if os(macOS)
    @State var image: NSImage
    #else
    @State var image: UIImage
    #endif
    @State var title: String
    @State var subtitle: String
    
    @EnvironmentObject var base_workspace: Workspace
    
    var body: some View
    {
        ZStack
        {
            Rectangle()
                .foregroundColor(color)
                .overlay
            {
                #if os(macOS)
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                #else
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                #endif
            }
            
            VStack
            {
                Spacer()
                HStack
                {
                    VStack(alignment: .leading)
                    {
                        Text(title)
                            .font(.headline)
                            .padding(.top, 8)
                            .padding(.leading, 4)
                        
                        Text(subtitle)
                            .foregroundColor(.gray)
                            .padding(.bottom, 8)
                            .padding(.leading, 4)
                    }
                    .padding(.horizontal, 8)
                    Spacer()
                }
                .background(color.opacity(0.2))
                .background(.thinMaterial)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
        .frame(height: 192)
        .shadow(radius: 8.0)
    }
}

//MARK: Large card preview for drag
struct LargeCardViewPreview: View
{
    @State var color: Color
    #if os(macOS)
    @State var image: NSImage
    #else
    @State var image: UIImage
    #endif
    @State var title: String
    @State var subtitle: String
    
    var body: some View
    {
        ZStack
        {
            Rectangle()
                .foregroundColor(color)
                .overlay
            {
                #if os(macOS)
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                #else
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                #endif
            }
            
            VStack
            {
                Spacer()
                HStack
                {
                    VStack(alignment: .leading)
                    {
                        Text(title)
                            .font(.headline)
                            .padding(.top, 8)
                            .padding(.leading, 4)
                        
                        Text(subtitle)
                            .foregroundColor(.gray)
                            .padding(.bottom, 8)
                            .padding(.leading, 4)
                    }
                    .padding(.horizontal, 8)
                    Spacer()
                }
                .background(color.opacity(0.2))
                .background(.thinMaterial)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
        .frame(height: 192)
    }
}

//MARK: - Small card view
struct SmallCardView: View
{
    @State var color: Color
    #if os(macOS)
    @State var image: NSImage
    #else
    @State var image: UIImage
    #endif
    @State var title: String
    
    var body: some View
    {
        ZStack
        {
            VStack
            {
                HStack(spacing: 0)
                {
                    HStack(spacing: 0)
                    {
                        Text(title)
                            .font(.headline)
                            .padding()
                        
                        Spacer()
                        
                        Rectangle()
                            .fill(.clear)
                            .overlay
                        {
                            #if os(macOS)
                            Image(nsImage: image)
                                .resizable()
                                .scaledToFill()
                            #else
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                            #endif
                        }
                        .frame(width: 64, height: 64)
                        .background(Color.clear)
                    }
                    /*.onTapGesture
                    {
                        detail_view_presented = true
                    }
                    .popover(isPresented: $detail_view_presented)
                    {
                        DetailView(document: $document, detail_item: $detail_item)
                            .onDisappear()
                        {
                            detail_view_presented = false
                        }
                    }*/
                    
                    Rectangle()
                        .foregroundColor(color)
                        .frame(width: 32, height: 64)
                }
            }
            .background(.thinMaterial)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
        .shadow(radius: 8.0)
    }
}

//MARK: Small card preview for drag
struct SmallCardViewPreview: View
{
    @State var color: Color
    #if os(macOS)
    @State var image: NSImage
    #else
    @State var image: UIImage
    #endif
    @State var title: String
    
    var body: some View
    {
        ZStack
        {
            VStack
            {
                HStack(spacing: 0)
                {
                    HStack(spacing: 0)
                    {
                        Text(title)
                            .font(.headline)
                            .padding()
                        
                        Spacer()
                        
                        Rectangle()
                            .fill(.clear)
                            .overlay
                        {
                            #if os(macOS)
                            Image(nsImage: image)
                                .resizable()
                                .scaledToFill()
                            #else
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                            #endif
                        }
                        .frame(width: 64, height: 64)
                        .background(Color.clear)
                    }
                    
                    Rectangle()
                        .foregroundColor(color)
                        .frame(width: 32, height: 64)
                }
            }
            .background(.thinMaterial)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
    }
}

//MARK: - Cards preview
struct Cards_Previews: PreviewProvider
{
    static var previews: some View
    {
        Group
        {
            VStack()
            {
                #if os(macOS)
                LargeCardView(color: .green, image: NSImage(), title: "Title", subtitle: "Subtitle")
                    .modifier(CircleDeleteButtonModifier(workspace: Workspace(), object_item: WorkspaceObject(), objects: [WorkspaceObject](), on_delete: { IndexSet in }, object_type_name: "name"))
                    .padding([.horizontal, .top])
                SmallCardView(color: .green, image: NSImage(), title: "Title")
                    .modifier(BorderlessDeleteButtonModifier(workspace: Workspace(), object_item: WorkspaceObject(), objects: [WorkspaceObject](), on_delete: { IndexSet in }, object_type_name: "none"))
                    .padding()
                #else
                LargeCardView(color: .green, image: UIImage(), title: "Title", subtitle: "Subtitle")
                    .modifier(CircleDeleteButtonModifier(workspace: Workspace(), object_item: WorkspaceObject(), objects: [WorkspaceObject](), on_delete: { IndexSet in }, object_type_name: "name"))
                    .padding([.horizontal, .top])
                SmallCardView(color: .green, image: UIImage(), title: "Title")
                    .modifier(BorderlessDeleteButtonModifier(workspace: Workspace(), object_item: WorkspaceObject(), objects: [WorkspaceObject](), on_delete: { IndexSet in }, object_type_name: "none"))
                    .padding()
                #endif
            }
            .padding(4)
            //.background(.white)
        }
    }
}
