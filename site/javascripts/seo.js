// Inject JSON-LD structured data for software library schema
(function () {
  const schema = {
    "@context": "https://schema.org",
    "@type": "SoftwareSourceCode",
    "name": "Arc",
    "description": "Pragmatic functional programming for Swift — async-first, production-ready, native.",
    "url": "https://cyrilleguipie.github.io/arc",
    "codeRepository": "https://github.com/cyrilleguipie/arc",
    "programmingLanguage": {
      "@type": "ComputerLanguage",
      "name": "Swift"
    },
    "runtimePlatform": ["iOS", "macOS", "tvOS", "watchOS"],
    "license": "https://opensource.org/licenses/MIT",
    "author": {
      "@type": "Person",
      "name": "Cyrille Guipié",
      "url": "https://github.com/cyrilleguipie"
    },
    "keywords": [
      "swift",
      "functional programming",
      "either",
      "validated",
      "effect",
      "async await",
      "ios",
      "vapor",
      "error handling",
      "type safety"
    ]
  };

  const script = document.createElement("script");
  script.type = "application/ld+json";
  script.textContent = JSON.stringify(schema);
  document.head.appendChild(script);
})();
