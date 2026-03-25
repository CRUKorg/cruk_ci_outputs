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