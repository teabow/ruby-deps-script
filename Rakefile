task default: %w[make_deps]

desc "creates a markdown file which lists packages dependencies"
task :make_deps do
    ruby "scripts/make_dependencies.rb #{ENV['output']} #{ENV['deps']}"
end
