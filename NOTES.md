# Notes

Will add up some notes regarding different configuration aspects.

## Manual steps

Configure Firefox policies to disable automatic app update:

```
cat > /Applications/Firefox.app/Contents/Resources/distribution/policies.json << EOF
{
  "policies": {
    "DisableAppUpdate": true
  }
}
EOF
```
