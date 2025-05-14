// Program.fs
// Main application entry point and UI implementation for OpenTADA

// Assuming Uno Platform with F# - structure might vary based on Uno templates
// This is a conceptual representation. Actual Uno Platform F# structure may differ.

namespace OpenTADA

open System
open Windows.UI.Xaml
open Windows.UI.Xaml.Controls
open Windows.UI.Xaml.Media
open Windows.UI.Xaml.Media.Imaging // For BitmapImage if used directly
open Windows.UI.Core // For WindowSizeChangedEventArgs if handling size changes directly
open Windows.Graphics.Display // For DisplayInformation

// It's common in Uno to have an App.xaml and App.xaml.fs for application lifecycle
// For simplicity, this conceptual Program.fs contains UI setup logic.
// In a full Uno app, this would likely be part of a Page or UserControl.

module App =

    let createUI() =
        let mainGrid = new Grid()

        // Define rows and columns for layout flexibility
        // For simplicity, let's assume a primary text area and an input bar, with an image.
        // More complex layouts would use more specific RowDefinitions and ColumnDefinitions.

        let storyDisplay = new TextBlock(
            Text = "Welcome to OpenTADA!\nLoading story...", // Initial text
            TextWrapping = TextWrapping.Wrap,
            VerticalAlignment = VerticalAlignment.Stretch,
            HorizontalAlignment = HorizontalAlignment.Stretch,
            Margin = Thickness(10.0)
        )

        let inputEntry = new TextBox(
            PlaceholderText = "Enter your command...",
            VerticalAlignment = VerticalAlignment.Bottom,
            Margin = Thickness(10.0)
        )
        // TODO: Add event handler for input submission (e.g., on KeyDown for Enter)

        let storyImage = new Image(
            // Placeholder source, to be updated by the application
            // Source = new BitmapImage(new Uri("ms-appx:///Assets/placeholder.png")),
            Stretch = Stretch.Uniform, // Or UniformToFill depending on desired behavior
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
            Margin = Thickness(10.0)
        )

        // --- UI Element Placement (Conceptual) ---
        // This is highly dependent on the root visual element (e.g., Page, UserControl)
        // and the chosen layout panels (Grid, StackPanel, etc.)

        // Example using a Grid for rough placement:
        // Row 0: Story Text Area (takes most space)
        // Row 1: Input Bar (at the bottom)
        // Image could be in a separate column or overlaid/managed dynamically.

        // Create a container for the story text and image (e.g., another Grid or StackPanel)
        let storyAndImageContainer = new Grid()
        storyAndImageContainer.ColumnDefinitions.Add(new ColumnDefinition(Width = GridLength.Auto)) // For Image
        storyAndImageContainer.ColumnDefinitions.Add(new ColumnDefinition(Width = new GridLength(1.0, GridUnitType.Star))) // For Text

        storyAndImageContainer.RowDefinitions.Add(new RowDefinition(Height = new GridLength(1.0, GridUnitType.Star)))

        // Add elements to storyAndImageContainer (order matters for Z-index if overlapping)
        // Grid.SetColumn(storyImage, 0) // Image in first column
        // Grid.SetRow(storyImage, 0)
        // storyAndImageContainer.Children.Add(storyImage) // Added first, potentially behind text if not managed

        Grid.SetColumn(storyDisplay, 1) // Text in second column
        Grid.SetRow(storyDisplay, 0)
        storyAndImageContainer.Children.Add(storyDisplay)

        // Add storyAndImageContainer and inputEntry to mainGrid
        mainGrid.RowDefinitions.Add(new RowDefinition(Height = new GridLength(1.0, GridUnitType.Star))) // For storyAndImageContainer
        mainGrid.RowDefinitions.Add(new RowDefinition(Height = GridLength.Auto)) // For inputEntry

        Grid.SetRow(storyAndImageContainer, 0)
        mainGrid.Children.Add(storyAndImageContainer)

        Grid.SetRow(inputEntry, 1)
        mainGrid.Children.Add(inputEntry)


        // --- Dynamic Image Sizing and Placement Logic ---
        // This would typically be handled in response to size change events or using adaptive triggers.
        let adaptLayout (width: double) (height: double) (isSmallScreen: bool) =
            // Reset image from mainGrid if it was added there directly for small screens
            if mainGrid.Children.Contains(storyImage) then
                mainGrid.Children.Remove(storyImage) |> ignore
            // Reset image from storyAndImageContainer if it was there
            if storyAndImageContainer.Children.Contains(storyImage) then
                storyAndImageContainer.Children.Remove(storyImage) |> ignore


            if isSmallScreen then
                // "image appears in the middle of the text at the time that it is rendered,
                // but scrolls off the screen as new text is added."
                // This implies the image might be embedded within the storyDisplay's content flow,
                // which is complex for a simple TextBlock.
                // A RichTextBlock or a custom control might be needed for true inline embedding.
                // For simplicity here, we'll place it above the text block on small screens,
                // assuming the storyDisplay is scrollable.
                // Or, it's added to the mainGrid in a way that it gets covered.
                // The description "in the middle of the text" is tricky with standard controls.

                // Simplified: Place image in the mainGrid, row 0, allow text to scroll over.
                // This doesn't truly put it "in the middle" of flowing text.
                // True "in the middle of the text" and scrolling off would likely require
                // dynamically inserting an Image element into a container that also holds text segments,
                // or using a WebView with HTML content.

                // For now, let's hide it on small screens or place it simply
                // storyImage.Visibility <- Visibility.Collapsed // Simplest, or:
                // Or adjust storyAndImageContainer to a single column/row layout
                storyAndImageContainer.ColumnDefinitions.Clear()
                storyAndImageContainer.RowDefinitions.Clear()
                storyAndImageContainer.RowDefinitions.Add(new RowDefinition(Height = GridLength.Auto)) // Image
                storyAndImageContainer.RowDefinitions.Add(new RowDefinition(Height = new GridLength(1.0, GridUnitType.Star))) // Text
                Grid.SetRow(storyImage, 0)
                Grid.SetColumn(storyImage, 0) // Span across if needed
                storyAndImageContainer.Children.Add(storyImage)

                Grid.SetRow(storyDisplay, 1)
                Grid.SetColumn(storyDisplay, 0)
                //storyAndImageContainer.Children.Add(storyDisplay) // Already there, just re-gridding


            else if width > height then // Landscape view
                // "image takes up half of the width of the interface and centered vertically."
                storyAndImageContainer.ColumnDefinitions.Clear()
                storyAndImageContainer.RowDefinitions.Clear()

                storyAndImageContainer.ColumnDefinitions.Add(new ColumnDefinition(Width = new GridLength(0.5, GridUnitType.Star))) // Image
                storyAndImageContainer.ColumnDefinitions.Add(new ColumnDefinition(Width = new GridLength(0.5, GridUnitType.Star))) // Text
                storyAndImageContainer.RowDefinitions.Add(new RowDefinition(Height = new GridLength(1.0, GridUnitType.Star)))

                storyImage.HorizontalAlignment <- HorizontalAlignment.Stretch
                storyImage.VerticalAlignment <- VerticalAlignment.Center
                Grid.SetColumn(storyImage, 0)
                Grid.SetRow(storyImage, 0)
                storyAndImageContainer.Children.Add(storyImage)

                Grid.SetColumn(storyDisplay, 1)
                Grid.SetRow(storyDisplay, 0)
                // storyAndImageContainer.Children.Add(storyDisplay) // Already there


            else // Portrait view (and not small screen)
                // "image takes up half the height of the interface and is centered horizontally."
                storyAndImageContainer.ColumnDefinitions.Clear()
                storyAndImageContainer.RowDefinitions.Clear()

                storyAndImageContainer.RowDefinitions.Add(new RowDefinition(Height = new GridLength(0.5, GridUnitType.Star))) // Image
                storyAndImageContainer.RowDefinitions.Add(new RowDefinition(Height = new GridLength(0.5, GridUnitType.Star))) // Text
                storyAndImageContainer.ColumnDefinitions.Add(new ColumnDefinition(Width = new GridLength(1.0, GridUnitType.Star)))


                storyImage.VerticalAlignment <- VerticalAlignment.Stretch
                storyImage.HorizontalAlignment <- HorizontalAlignment.Center
                Grid.SetRow(storyImage, 0)
                Grid.SetColumn(storyImage, 0)
                storyAndImageContainer.Children.Add(storyImage)

                Grid.SetRow(storyDisplay, 1)
                Grid.SetColumn(storyDisplay, 0)
                // storyAndImageContainer.Children.Add(storyDisplay) // Already there

        // Initial layout call (example, assuming you get initial window dimensions)
        // In a real app, this would be tied to Window.Current.SizeChanged or Page.SizeChanged events.
        // For example:
        // Window.Current.SizeChanged.Add(fun args ->
        //     let newWidth = args.Size.Width
        //     let newHeight = args.Size.Height
        //     // Determine isSmallScreen based on DPI and physical size (more complex)
        //     let displayInfo = DisplayInformation.GetForCurrentView()
        //     // Example threshold, needs refinement
        //     let isSmall = newWidth < 600.0 || newHeight < 600.0 // Arbitrary threshold
        //     adaptLayout newWidth newHeight isSmall
        // )

        // For initial setup, can use a default assumption or try to get current size if available synchronously.
        // This is simplified.
        // adaptLayout initialWidth initialHeight initialIsSmall

        mainGrid // Return the root UI element

    type MainWindow() =
        inherit Application()

        override this.OnLaunched(args) =
            let window = Windows.UI.Xaml.Window.Current
            if isNull window.Content then
                // Create a Frame to act as the navigation context
                let rootFrame = new Frame()
                
                // Place the frame in the current Window
                window.Content <- rootFrame
                
                // Set the UI content
                rootFrame.Content <- createUI()
            
            window.Activate()

    [<EntryPoint>]
    let main args =
        // Initialize the Uno Platform host
        let host = Uno.UI.Runtime.Skia.SkiaHost()
        host.Initialize()
        
        Application.Start(fun _ -> 
            let app = new MainWindow()
            ()
        )
        0