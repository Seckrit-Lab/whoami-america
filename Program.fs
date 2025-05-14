open Uno.UI.Skia.Gtk
open Windows.UI.Xaml.Controls
open Uno.UI

type MainPage() =
    inherit Page()

    let InitializeComponent() =
        let grid = Grid()
        let text = TextBlock()
        text.Text <- "Welcome to OpenTADA"
        text.HorizontalAlignment <- HorizontalAlignment.Center
        text.VerticalAlignment <- VerticalAlignment.Center
        grid.Children.Add(text)
        base.Content <- grid

    do
        InitializeComponent()

[<EntryPoint>]
let main argv =
    let host = new GtkHost()

    Windows.UI.Xaml.Application.Start(fun _ ->
        let app = Windows.UI.Xaml.Application()

        app.add_Startup(fun sender args ->
            let window = Windows.UI.Xaml.Window()
            window.Content <- MainPage()
            window.Activate())

        app)

    0