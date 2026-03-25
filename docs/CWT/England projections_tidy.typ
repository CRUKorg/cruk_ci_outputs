// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = line(start: (25%,0%), end: (75%,0%))

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.abs
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == str {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == content {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != str {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black, body_background_color: white) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: body_background_color, width: 100%, inset: 8pt, body))
      }
    )
}



#let article(
  title: none,
  subtitle: none,
  authors: none,
  date: none,
  abstract: none,
  abstract-title: none,
  cols: 1,
  lang: "en",
  region: "US",
  font: "libertinus serif",
  fontsize: 11pt,
  title-size: 1.5em,
  subtitle-size: 1.25em,
  heading-family: "libertinus serif",
  heading-weight: "bold",
  heading-style: "normal",
  heading-color: black,
  heading-line-height: 0.65em,
  sectionnumbering: none,
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  doc,
) = {
  set par(justify: true)
  set text(lang: lang,
           region: region,
           font: font,
           size: fontsize)
  set heading(numbering: sectionnumbering)
  if title != none {
    align(center)[#block(inset: 2em)[
      #set par(leading: heading-line-height)
      #if (heading-family != none or heading-weight != "bold" or heading-style != "normal"
           or heading-color != black) {
        set text(font: heading-family, weight: heading-weight, style: heading-style, fill: heading-color)
        text(size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(size: subtitle-size)[#subtitle]
        }
      } else {
        text(weight: "bold", size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(weight: "bold", size: subtitle-size)[#subtitle]
        }
      }
    ]]
  }

  if authors != none {
    let count = authors.len()
    let ncols = calc.min(count, 3)
    grid(
      columns: (1fr,) * ncols,
      row-gutter: 1.5em,
      ..authors.map(author =>
          align(center)[
            #author.name \
            #author.affiliation \
            #author.email
          ]
      )
    )
  }

  if date != none {
    align(center)[#block(inset: 1em)[
      #date
    ]]
  }

  if abstract != none {
    block(inset: 2em)[
    #text(weight: "semibold")[#abstract-title] #h(1em) #abstract
    ]
  }

  if toc {
    let title = if toc_title == none {
      auto
    } else {
      toc_title
    }
    block(above: 0em, below: 2em)[
    #outline(
      title: toc_title,
      depth: toc_depth,
      indent: toc_indent
    );
    ]
  }

  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }
}

#set table(
  inset: 6pt,
  stroke: none
)

#set page(
  paper: "a4",
  margin: (x: 2cm,y: 2cm,),
  numbering: "1",
)

// typst-show.typ

#set text(
  font: "Poppins",
  size: 11pt,
  fill: rgb("#000000")
)

#show heading.where(level: 1): it => text(
  font: "Progress",
  size: 32pt,
  fill: rgb("#000000"),
  weight: "medium",
  it
)

#show heading.where(level: 2): it => text(
  font: "Progress",
  size: 24pt,
  fill: rgb("#000000"),
  weight: "medium",
  it
)

#show heading.where(level: 3): it => text(
  font: "Progress",
  size: 20pt,
  fill: rgb("#000000"),
  weight: "medium",
  it
)

#pagebreak(weak: true)
== Context
<context>
Currently we have a set of referrals and waiting times projections for
England that are frequently used in press releases and published
content. While the NI projections have recently been produced, the data
for the England projections is now a couple of years old, and we've
received requests around if these statements could be updated.
Furthermore, with influencing ramping up in Scotland and Wales around
their elections, it would be beneficial to produce estimates for these
nations too.

=== Statements to be updated/produced:
<statements-to-be-updatedproduced>
By 2030 in England, there are expected to be XX% more urgent cancer
referrals each year, up from XXX,000 in 2025 to around
X,XXX,000.#footnote[Previously calculated based on the difference
between urgent suspected cancer referrals from July 2023 to June 2024
compared with the projected number of referrals estimated in July 2028
to June 2029]

More than XXX,000 cancer patients in England are estimated to begin
treatment later than they should over the next five years if current
performance continues.#footnote[Previously calculated by modelling the
number of patients projected to start treatment on the 62-day pathway,
and applying the mean performance figure from the last 6 months of
historic data. By calculating the difference between this and how many
patients would have started treatment within 62 days if 85% of patients
were seen on time, 301,000 are projected to not start treatment within
standard from July 2024 to June 2029.]

#v(1em)
#pagebreak(weak: true)
== Urgent referrals statement
<urgent-referrals-statement>
Data source: `USCR to FOA tab of the SST dashboard`

#block[
]
#block[
]
#grid(columns: (1fr, 1fr), gutter: 2em, align: top,
[#set par(justify: true)
We think we should preference the FDS statement. If we are to use the
urgent referrals statement it shouldn't appear alongside the FDS
statement (due to how easily they can confuse).
],
[#set par(justify: true)
This was previously calculated based on the difference between urgent
suspected cancer referrals from July 2023 to June 2024 compared with the
projected number of referrals estimated in July 2028 to June 2030.
]
)
#block(stroke: 2pt + rgb("#000000"), inset: (x: 24pt, y: 16pt), radius: 0pt, width: 100%)[By 2030 there are expected to be 23% more urgent cancer referrals each
year in England, up from around 3,250,000 in 2025 to around 4,000,000
referrals.#footnote[This statement only covers urgent suspected cancer,
which is different to the later FDS numbers which have a wider inclusion
criteria. \
\
This metric was previously treated as the total number of USC referrals.
Technically I think it is slightly less, and is instead the number of
USC referrals that have attended their first outpatient appointment. For
example, 2022/23 USCR data shows 2,889,406 patients, whereas USC
referral numbers list 2,896,111. This is a small difference, and it is
reasonable to expect all referrals to have an outpatient appointment
during their care.]
]
#block[
#block[
#box(image("England-projections_tidy_files/figure-typst/USCR.chart-1.svg"))

]
]
#v(1em)
#pagebreak(weak: true)
== Faster Diagnosis Standard
<faster-diagnosis-standard>
Data source: `FDS tab of the SST dashboard`

#grid(columns: (1fr, 1fr), gutter: 2em, align: top,
[#set par(justify: true)
NHS England has the Faster Diagnosis Standard (FDS) which focuses on
timely diagnosis. The target is that 80%#footnote[This statement only
covers urgent suspected cancer, which is different to the later FDS
numbers which have a wider inclusion criteria. \
\
This metric was previously treated as the total number of USC referrals.
Technically I think it is slightly less, and is instead the number of
USC referrals that have attended their first outpatient appointment. For
example, 2022/23 USCR data shows 2,889,406 patients, whereas USC
referral numbers list 2,896,111. This is a small difference, and it is
reasonable to expect all referrals to have an outpatient appointment
during their care.];\[^3\] of people referred should not wait more than
28 days from referral to finding out whether you
],
[#set par(justify: true)
have cancer or not. The standard includes urgent suspected cancer
referrals, urgent screening referrals and breast symptomatic referrals.
It does not include consultant upgrades that is included in the 62 day
metric.
]
)
#block[
]
#block[
]
#block(stroke: 2pt + rgb("#000000"), inset: (x: 24pt, y: 16pt), radius: 0pt, width: 100%)[By 2030 there are expected to be 26.2% more urgent cancer referrals
receiving a diagnosis or having cancer ruled out, each year in England,
up from around 3,360,000 in 2025 to around 4,250,000.

12 month average performance (76.2%)

If current FDS performance continues, nearly 719,000 people in England
are estimated to wait longer than they should to found out if they have
cancer or not over the next five years.
]
#emph[We need to adjust the people wording here as it is referrals not
people, and a person could have multiple referrals (approximately one
fifth of people have more than 1 referral).]

#block[
#block[
#box(image("England-projections_tidy_files/figure-typst/FDS.chart-1.svg"))

]
]
#v(1em)
#pagebreak(weak: true)
== 62 day statement
<day-statement>
Data source: `SST hub and CWT site (for historical other routes)`

In England, 85% of patients should start their first definitive
treatment within 62 days of an urgent suspected cancer referral, breast
symptomatic referral, urgent cancer screening programme referral or
consultant upgrade.

Previously calculated by modelling the number of patients projected to
start treatment on the 62-day pathway that were referred and applying
the mean performance figure from the last 6 months of historic data.

We initially did linear regression for this which is used for all the
other metrics, however we don't think this really fits the trend in the
data, so also ran a poisson model which seems to be much more
appropriate.

=== Linear modelling
<linear-modelling>
With the linear regression model, there is a clear sustained increase in
number of patients starting treatment after October 2023. If we did use
this model, then the final numbers would likely underestimate the actual
number of patients of the next 5 years.

#block[
]
#block[
]
#block[
#block[
#box(image("England-projections_tidy_files/figure-typst/62_chart-1.svg"))

]
]
=== Poisson modelling
<poisson-modelling>
There are different trends present for each referral route, so I have
modelled them separately. I have also modelled the three major referral
routes together - the breast symptomatic route has not been included in
this work as it only goes back to October 2023, but does contain around
100 people each month.

#block[
#block[
#block[
#block[
#box(image("England-projections_tidy_files/figure-typst/Consultant.Poisson-1.svg"))

]
]
The poisson model for consultant is a much better fit.

It isn't clear why there was such a large jump in consultant referrals
from October 2023, but this is when it became part of the official
standard. Data for this referral was available back to 2009 though, when
it was far lower. This jump is what is missed by the linear model, and
consultant has a different trend to other routes for some reason.

]
#block[
Consultant
]
#block[
#block[
#block[
#box(image("England-projections_tidy_files/figure-typst/USC.poisson-1.svg"))

]
]
USC has a broadly linear trend, which the poisson model has retained.

]
#block[
USC
]
#block[
#block[
#block[
#box(image("England-projections_tidy_files/figure-typst/screening.poisson-1.svg"))

]
]
Screening seems to be following a linear trend if you consider the whole
time series. I don't know what the reasoning was for the gradual
increase up to the end of 2017, or what caused it to seemingly reset
back down to the linear trend.

]
#block[
Screening
]
#block[
#block[
#block[
#box(image("England-projections_tidy_files/figure-typst/unnamed-chunk-1-1.svg"))

]
]
This combined referral route model does a reasonable job of following
the data trend. However, given that there are different trends in each
of the referral routes, it makes more sense to have three different
models, and then sum the results of those models.

]
#block[
Combined
]
]
#v(1em)
#pagebreak(weak: true)
== Aggregated 62 day projection
<aggregated-62-day-projection>
In the following graph you can see the comparison of poisson modelling
compared to linear modelling. Given that there are different trends in
each of the referral routes, it makes more sense to have three different
models, and then sum the results of those models which is the
#strong[aggregated] projection on this graph.

#block[
]
#block(stroke: 2pt + rgb("#000000"), inset: (x: 24pt, y: 16pt), radius: 0pt, width: 100%)[12 month average performance (69.2%)

Nearly 337,000 cancer patients in England are estimated to begin
treatment later than they should over the next five years if current
performance continues.
]
#block[
#block[
#box(image("England-projections_tidy_files/figure-typst/linear.v.poisson-1.svg"))

]
]
#v(1em)




