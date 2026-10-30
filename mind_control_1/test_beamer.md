---
title: "test beamer"
author: "Scott Axelrod"
fontsize: 10pt
classoption:
  - "aspectratio=1610"
---


# Section Slide (Creates a divider/title slide)

Compile This with:

```
> pandoc -t beamer test_beamer.md -o test_beamer_slides.pdf -H beamer_header.tex -i -V theme:default # used to match plain pdf
> pandoc -t beamer test_beamer.md -o test_beamer_slides.pdf -V theme:Rochester -V colortheme:dolphin # solid, polished color banner at top, no footer
> pandoc -t beamer test_beamer.md -o test_beamer_slides.pdf -i   -V theme:Pittsburgh # clean, title on top right, no footer
> pandoc -t beamer test_beamer.md -o test_beamer_slides.pdf -i   -V theme:Madrid -V colortheme:dolphin # has footer
```

Theme Madrid put foote on every slide.

## Slide Title

Some regular slide text here.

- First point appears on click
- Second point appears on click
- Third point appears on click

. . .

This paragraph appears only after all bullets are revealed (using the native pause syntax).

\newpage

## Next Slide

::: nonincremental
- Point A (shows immediately)
- Point B (shows immediately)
:::



# First header

A non-incremental list:

::: nonincremental
- L3 item 1
- L3 item 2
:::


- L1 item 1 
- L1 item 2

A second incremental list:

- L2 item 1 
- L2 item 2

And another non-incremental list:

::: nonincremental
- L3 item 1
- L3 item 2
:::

\newpage

## a subheader

A picture :

![Stories in the Dystopian Architecture](stories_in_a_dystopian_arc.jpg){width=90%}

# another subheader

With a 

### sub-sub header

- an another lis

  > with a quote inside

\newpage

## A New Header

::::: columns
::: {.column width="50%"}
Here is some text explaining the diagram:

- First point
- Second point
- Third point
:::

::: {.column width="50%"}
![](stories_in_a_dystopian_arc.jpg)
:::
:::::


\newpage

#  Course Overview


\centering
![](mind_control_arc_lab.svg){height=60%}

\raggedright
\small

<!-- <img src="mad_scientists_with_narrative_lenses_of_dystopian_arc_nocaption.png" alt="Course Overview" width=" 90%"> -->  <!-- % width="250px" or "width=50%" -->
<!--- <img src="mind_control_arc_lab.svg" alt="Course Overview" width=" 90%"> --> <!-- % width="250px" or "width=50%" --> 


- Look at modern age stories where societies impose/offer mind control.
- Consider characters who are rebelling.
- Ask questions through various lenses.


\newpage

---

<!-- --- gives new slide , I omit title 
# Stories in a Dystopian Arc  
--> 

\centering
![](stories_in_a_dystopian_arc.jpg){height=60%}

\raggedright
\small

- Dostoyevsky's Underground Man, isolated and being crushed by 2+2=4 reason .
- Winston from "1984" being pounded by Big Brother to truly believe 2+2=5.
- Neo from "The Matrix" perceiving that his entire world is a computer simulation, seeing the simulation of 2+2=4 in binary.
- Sai from "The Perfect Match" being nudged by the AI agent Tilly to tell him that he prefers the beautiful girl in the "2+2=4" T-shirt.


\newpage

---

<!--  --- gives new slide , I omit title 
# Some Lenses
-->

\centering
![](lenses.png){height=53%}


\raggedright
\small

- **Human Outlier Analysis** (Michel Foucault -- Madness and Confinement)
  <!-- - Knowledge and Limits of Thought -->
   <!-- - Postmodernism label applied to him.  -->
- **Disiplinary Survellience** (Michel Foucalt -- Panopticism)
- **Narrative Analysis** (Jerome Bruner ):
- **Societal Control** (Gilles Deluze):
  - Foucault’s "enclosures" (prisons, schools, hospitals) are breaking down.
  - We are no longer "individuals" in a room; we are "dividuals"—data points, bank codes, and digital footprints that are tracked in an open, continuous loop of control.
  - It’s not about being locked in a cage; it’s about being part of a network where the "control" is fluid and constant.
- **False Needs** (Herbert Marcuse)
- **Surveillance Capitalism** (Soshanna Zuboff:)

