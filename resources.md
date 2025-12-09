# Welcome
This is where I list all the resources & references I've used while working on [Lyrae Path Traced Shaders](https://modrinth.com/shader/lyrae-shaders). I hope it helps you too!

Each resource is labeled with a symbolic marker. This is not any kind of official classification, it's simply my own way of organizing the material.
- `◆` is for technical research papers, official talks, lectures and mostly academically rigorous material.
- `◇` is for more approachable tutorials, explaratory articles and casual blogs.

### Table of Content
- [**Physically Based Rendering**](#physically-based-rendering): Ray traced rendering and physically based light transport in general.
- [**Render Stability**](#render-stability): Improving the stochastic nature of Monte Carlo on low sample counts and reducing noise.
- [**Supplementary Topics**](#supplementary-topics): Not strictly related to path tracing, but still useful for physically based rendering.


# Physically Based Rendering
- ◆ TU Wien — [2021 Rendering Lectures](https://www.youtube.com/watch?v=5sY_hoh_IDc&list=PLmIqTlJ6KsE2yXzeq02hqCDpOdtj6n6A9&index=1)
- ◆ P. Shirley, T. Black, S. Hollasch — ["Ray Tracing in One Weekend" book series](https://raytracing.github.io/)
- ◇ M. Pharr, W. Jakob, and G. Humphreys — ["Physically Based Rendering" book](https://www.pbr-book.org/4ed/contents)
- ◇ Scratchapixel — [Ray tracing articles](https://www.scratchapixel.com/)
- ◆ Brian Karis — [Real Shading in Unreal Engine 4](https://blog.selfshadow.com/publications/s2013-shading-course/karis/s2013_pbs_epic_notes_v2.pdf)
- ◆ Brent Burley — [Physically Based Shading at Disney](https://media.disneyanimation.com/uploads/production/publication_asset/48/asset/s2012_pbs_disney_brdf_notes_v3.pdf)
- ◆ R. Guy, M. Agopian — [Physically Based Rendering in Filament](https://google.github.io/filament/Filament.md.html)
- ◆ B. Walter et al — [Microfacet Models for Refraction through Rough Surfaces](https://www.graphics.cornell.edu/~bjw/microfacetbsdf.pdf)
- ◆ Academy Software — [OpenPBR specification](https://academysoftwarefoundation.github.io/OpenPBR/)
- ◇ Marco Alamia — [Physically Based Rendering - Cook-Torrance](http://www.codinglabs.net/article_physically_based_rendering_cook_torrance.aspx)
- ◇ Joe Schutte — ["Implementing the Disney BSDF" blog](https://schuttejoe.github.io/post/disneybsdf/)

# Render Stability
- ◆ E. Heitz et al — [A Low-Discrepancy Sampler that Distributes Monte Carlo Errors as a Blue Noise in Screen Space](https://eheitzresearch.wordpress.com/762-2/)
- ◆ H. Dammertz et al — [Edge-Avoiding À-Trous Wavelet Transform for fast Global Illumination Filtering](https://jo.dreggn.org/home/2010_atrous.pdf)
- ◆ C. Schied et al — [Spatiotemporal Variance-Guided Filtering: Real-Time Reconstruction for Path-Traced Global Illumination](https://cg.ivd.kit.edu/publications/2017/svgf/svgf_preprint.pdf)
- ◇ Jacco Bikker — [Reprojection in a Ray Tracer](https://jacco.ompf2.com/2024/01/18/reprojection-in-a-ray-tracer/)

# Supplementary Topics
- ◆ A. J. Preetham et al — [A Practical Analytic Model for Daylight](https://courses.cs.duke.edu/cps124/spring08/assign/07_papers/p91-preetham.pdf)
- ◇ John Chapman — [Dynamic Local Exposure](https://john-chapman.github.io/2017/08/23/dynamic-local-exposure.html)