Get-ChildItem ".\examples\" -Filter *_example.rb | Foreach-Object { ruby $_.FullName }
