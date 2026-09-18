return function(require)
    return {
        ["Hero"] = {
            Button = "cursor-arrow-rays#fill",
            Slider = "adjustments-horizontal#fill",
            Page = "rectangle-stack#fill",
            Toggle = "check-circle#fill",
            Section = "rectangle-group#fill",
        },

        ["Phosphor"] = {
            Button = "cursor-click#fill",
            Slider = "sliders-horizontal#fill",
            Page = "squares-four#fill",
            Toggle = "toggle-right#fill",
            Section = "rows#fill",
        },

        ["Remix"] = {
            Button = "cursor#fill",
            Slider = "equalizer#fill",
            Page = "pages#fill",
            Toggle = "toggle#fill",
            Section = "layout-row#fill",
        },

        ["Lucide"] = {
            Button = "mouse-pointer-click",
            Slider = "sliders-horizontal",
            Page = "panels-top-left",
            Toggle = "toggle-right",
            Section = "rows-3",
        },

        ["Tabler"] = {
            Button = "pointer#fill",
            Slider = "adjustments-horizontal#fill",
            Page = "layout-grid#fill",
            Toggle = "toggle-right#fill",
            Section = "layout-rows",
        },

        -- Material variants
        ["Material/400_24_rounded"] = {
            Button = "touch-app",
            Slider = "tune",
            Page = "web-asset",
            Toggle = "toggle-on",
            Section = "view-agenda",
        },
    }
end