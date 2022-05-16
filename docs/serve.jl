using Pkg

Pkg.develop(path = "..")

using Revise
using Publish
using Hyperelastics

p = Publish.Project(Hyperelastics)

# serve documentation
serve(Hyperelastics)