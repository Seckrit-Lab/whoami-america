namespace Tada

open Avalonia
open Avalonia.Controls
open Avalonia.Controls.ApplicationLifetimes
open Avalonia.Markup.Xaml

type MainWindow() as this =
    inherit Window()
    
    do
        AvaloniaXamlLoader.Load(this)
        let inputText = this.FindControl<TextBox>("InputText")
        let outputText = this.FindControl<TextBox>("OutputText")
        
        inputText.KeyDown.Add(fun e ->
            if e.Key = Input.Key.Enter then
                outputText.Text <- outputText.Text + inputText.Text + "\n"
                inputText.Text <- ""
        )

type App() =
    inherit Application()
    
    override this.Initialize() =
        //this.Styles.Add(Styling.Styles.FluentDark())
        AvaloniaXamlLoader.Load(this)

    override this.OnFrameworkInitializationCompleted() =
        match this.ApplicationLifetime with
        | :? IClassicDesktopStyleApplicationLifetime as desktop ->
            desktop.MainWindow <- MainWindow()
        | _ -> ()
        base.OnFrameworkInitializationCompleted()

module Program =
    [<EntryPoint>]
    let main argv =
        AppBuilder
            .Configure<App>()
            .UsePlatformDetect()
            .StartWithClassicDesktopLifetime(argv)