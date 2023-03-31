#import "theme.typ": make_theme, data, assert_theme, current-slide

#let section = state("section", none)
#let subslide = counter("subslide")
#let logical-slide = counter("logical-slide")
#let repetitions = counter("repetitions")
#let cover-mode = state("cover-mode", "hide")

#let cover-mode-hide = cover-mode.update("hide")
#let cover-mode-mute = cover-mode.update("mute")

// avoid "#set" interferences
#let full-box(obj) = {
    box(
        width: 100%, height: auto, baseline: 0%, fill: none,
        stroke: none, radius: 0%, inset: 0%, outset: 0%,
        obj
    )
}

#let slide(theme: none, max-repetitions : 10, body) = {
    if theme == none {panic("slide must be called with a theme parameter.")}
    
    pagebreak(weak: true)
    logical-slide.step()
    locate( loc => {
        subslide.update(1)
        repetitions.update(1)
        show heading.where(level: 2): h => full-box(h.body)

        for _ in range(max-repetitions) {
            locate( loc-inner => {
                let curr-subslide = subslide.at(loc-inner).first()
                if curr-subslide <= repetitions.at(loc-inner).first() {
                    if curr-subslide > 1 { pagebreak(weak: true) }
                    body
                }
            })
            subslide.step()
        }
    })
}

#let slides-custom-hide(body) = {
    locate( loc => {
        let mode = cover-mode.at(loc)
        // wrap in box to avoid hiding issues with list, equation and other types
        if mode == "hide" {
            hide(full-box(body))
        } else if mode == "mute" {
            text(gray.lighten(50%), full-box(body))
        } else {
            panic("Illegal `cover-mode`: " + mode)
        }
    })
}

#let only(visible-slide-number, body) = {
    repetitions.update(rep => calc.max(rep, visible-slide-number))
    locate( loc => {
        if subslide.at(loc).first() == visible-slide-number {
            full-box(body)
        } else {
            slides-custom-hide(body)
        }
    })
}

#let beginning(first-visible-slide-number, body) = {
    repetitions.update(rep => calc.max(rep, first-visible-slide-number))
    locate( loc => {
        if subslide.at(loc).first() >= first-visible-slide-number {
            full-box(body)
        } else {
            slides-custom-hide(body)
        }
    })
}

#let until(last-visible-slide-number, body) = {
    repetitions.update(rep => calc.max(rep, last-visible-slide-number))
    locate( loc => {
        if subslide.at(loc).first() <= last-visible-slide-number {
            full-box(body)
        } else {
            slides-custom-hide(body)
        }
    })
}

#let one-by-one(start: 1, ..children) = {
    repetitions.update(rep => calc.max(rep, start + children.pos().len() - 1))
    for idx, child in children.pos() {
        beginning(start + idx, child)
    }
}

#let slides(
    data : none,
    theme : make_theme(),
    document_body
) = {
    if data == none {
        panic("data is none, use data() to provide this slide information.")
    }
    show heading.where(level: 1): h => {
        section.update(h.body)
    }

    show heading.where(level: 2): h => {
        pagebreak(weak: true)
        logical-slide.step()
        h
    }

    set text(
        size: theme.text-size,
    )
    let this-slide = current-slide(
        section: section,
        logical-slide: logical-slide,
        subslide: subslide,
    )

    set page(
        paper: "presentation-16-9",
        margin: theme.margin,
        header: theme.header.with(data, theme, this-slide)(),
        header-ascent: theme.header-ascent,
        footer: theme.footer.with(data, theme, this-slide)(),
        footer-descent: theme.footer-descent,
    )

    [
        #theme.title-slide.with(theme,data)()
        #document_body
    ]
}
