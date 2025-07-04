Browse Hub, just like Learn Hub. Options to browse by tag (already exists), by period, by author

Double tap to favourite.

If double tap a lot, that means user really likes the quote

Profile section: before anything, switch to enable/disable personalised suggestions (enabled by default). This will just be us specially curating and picking quotes we think the user will enjoy. When personalised suggestions is turned off, we just serve the user random quotes (like right now). When it's turned on, we inspect what the user likes (through favourites and really really favourites), use metadata around tags, period, sentimentality, intensity, quote length, author etc. etc. - everything basically - and write a personalised recommendation engine to recommend them more quotes theyll like.

As a reminder, here's the schema:

{
    "id": "master_000142",
    "text": "To write poetry after Auschwitz is barbaric.",
    "author": {
      "name": "Theodor Adorno",
      "birth": 1903,
      "death": 1969
    },
    "sources": [
      "yale"
    ],
    "source": "\u201cKulturkritik und Gesellschaft\u201d (1951)",
    "tags": [],
    "year": 1951,
    "author_score": 2,
    "overlap_factor": [],
    "status": "verified",
    "gpt": {
      "id": "master_000142",
      "relevance_score": 10,
      "interpretation": "This quote suggests that creating art, particularly poetry, in the aftermath of immense suffering and atrocity is an act that may seem trivial or inappropriate. Adorno critiques the ability of art to respond to the horrors of events like the Holocaust, raising questions about the role of culture in the face of human suffering.",
      "source_blurb": "Adorno's statement reflects post-war existential concerns about the limits of art and culture.",
      "tags": [
        "art",
        "truth",
        "death"
      ],
      "tone": {
        "label": "reflective",
        "intensity": 80
      },
      "sentiment_score": -0.5,
      "period": "Post-War"
    }
  },


