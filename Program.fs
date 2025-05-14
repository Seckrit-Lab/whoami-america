open System
open System.Windows.Forms
open System.Drawing

type MainForm() as this =
    inherit Form()
    
    // Main output text area
    let outputText = new RichTextBox(
        Dock = DockStyle.Fill,
        ReadOnly = true,
        Multiline = true
    )
    
    // Image display area
    let imageBox = new PictureBox(
        Dock = DockStyle.Left,
        SizeMode = PictureBoxSizeMode.Zoom,
        Width = 200
    )
    
    // Input text box
    let inputText = new TextBox(
        Dock = DockStyle.Bottom,
        Height = 25
    )

    do
        this.Text <- "OpenTADA"
        this.Size <- new Size(800, 600)
        
        this.Controls.Add(outputText)
        this.Controls.Add(imageBox) 
        this.Controls.Add(inputText)

        inputText.KeyPress.Add(fun e ->
            if e.KeyChar = '\r' then
                // TODO: Process input
                outputText.AppendText(inputText.Text + "\n")
                inputText.Clear()
        )

[<EntryPoint>]
let main argv =
    Application.EnableVisualStyles()
    Application.SetCompatibleTextRenderingDefault(false)
    Application.Run(new MainForm())
    0