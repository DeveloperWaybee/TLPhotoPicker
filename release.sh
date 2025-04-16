git add -A && git commit -m "Release 1.0.5"
git tag '1.0.5'
git push --tags
git push origin
pod trunk push DW_TLPhotoPicker.podspec