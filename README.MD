# Ruby dependencies list script

## Use

Only supports following dependencies :

- **node** (package.json)
- **cocoapods** (Podfile)
- **gradle** (build.gradle)

You can run the script with `rake`.

__Examples__ :

One file :
```
rake output=DEPS.MD deps=path/to/Podfile
```

Multiple files :
```
rake output=DEPS.MD deps=/path/to/package.json,path/to/Podfile,path/to/build.gradle
```

## TODO

- find and replace versions declare as variables
