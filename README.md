# GloamUI

There is no documentation as of yet, if you need guidance you can look into the source code and look for `v1/components/[Component].luau` and see the commented docs.

## Previews

### Quickstart to making a [Screen](https://github.com/AlexanderTheWorst/Gloam/blob/main/v1/components/Screen.luau), [Window](https://github.com/AlexanderTheWorst/Gloam/blob/main/v1/components/Window.luau) and a [Button](https://github.com/AlexanderTheWorst/Gloam/blob/main/v1/components/Button.luau)
```lua
local Gloam = loadstring(httpget("https://raw.githubusercontent.com/AlexanderTheWorst/Gloam/refs/heads/main/v1/index.luau"))()

local screen = Gloam.Screen({
    id = "Test"
})

local window = screen.Window({
    title = "Test"
})

local page = page.Page({
    title = "Test"
})

local button = page.Button({
    label = "Test",

    Gloam.Events.onClick(function() 
        print("I was clicked!")
    end)
})
```

### [Sliders](https://github.com/AlexanderTheWorst/Gloam/blob/main/v1/components/Slider.luau) with steps
```lua
local slider = page.Slider({
    label = "0 - 10",

    min = 0,
    max = 0,
    step = 2,

    Gloam.Events.onChange(print) --> Prints the new value, in this case in 2 step increments.
})
```

### [Toggle](https://github.com/AlexanderTheWorst/Gloam/blob/main/v1/components/Toggle.luau) with steps
```lua
local toggle = page.Toggle({
    label = "Test toggle",

    Gloam.Events.onToggle(print), --> Works
    Gloam.Events.onChange(print), --> Works
})
```

## Icon Packs

### Making a [Screen](https://github.com/AlexanderTheWorst/Gloam/blob/main/v1/components/Screen.luau) with a specific pack
```lua
local screen = Gloam.Screen({
    id = "Test",

    iconPack = Gloam.IconPack("Phosphor") --> Now uses the Phosphor icon pack
})
```
*By default it uses the [Hero](https://github.com/AlexanderTheWorst/Gloam/tree/main/Icons/Hero) icon pack*

### Creating components with a specific icon
```lua
local button = screen.Button({
    label = "Test",

    icon = Gloam.Icon("address-book"), --> This inherits the pack from the Screen context, in this case Phosphor

    icon = Gloam.Icon("home#fill", Gloam.IconPack("Hero")), --> But you can also mix and match

    icon = "rbxassetid://108462384317001" --> Or you can just use your own assets
})
```
*This is also supported by every other major component*

### Some icon packs have variants such as [Material](https://github.com/AlexanderTheWorst/Gloam/tree/main/Icons/Material)
```lua
local screen = Gloam.Screen({
    id = "Test",

    iconPack = Gloam.IconPack("Phosphor", {
        variant = "400_24_rounded"
    }) --> Now uses the Material/400_24_rounded icon pack
})
```

---

### But the project is far from finished, here's a list of what I plan to add!

#### Components
- [ ]  Toasts
- [ ]  Modals
- [ ]  Text Inputs and Text Box
- [ ]  Color Input
- [ ]  Resizable Windows

#### Customizability
- [ ]  Custom themes and theme creator

### The project is made to be versatile so feel free to look into the source code, and propose changes!