# ShortUUID

A Swift library that generates concise, unambiguous, URL-safe UUIDs. Based on and compatible with the Python library [shortuuid](https://github.com/skorokithakis/shortuuid) and Go library [shortuuid](https://github.com/lithammer/shortuuid).

## Usage

```swift
import ShortUUID

let su = ShortUUID()
```

You can then generate a short UUID

```swift
su.uuid() // vytxeTZskVKR7C7WgdSP3d
```

If you prefer a version 5 UUID, you can pass a name (DNS or URL) to the call and it will be used as a namespace (uuid.NAMESPACE_DNS or uuid.NAMESPACE_URL) for the resulting UUID:
```swift
su.uuid(name: "example.com") // wpsWLdLt9nscn2jbTD3uxe
su.uuid(name: "http://example.com") // c8sh5y9hdSMS6zVnrvf53T
```

You can also generate a cryptographically secure random string (using os.urandom(), internally) with:

```swift
su.random(length: 22) // RaF56o2r58hTKT7AYS9doj
```

To see the alphabet that is being used to generate new UUIDs:

```swift
su.alphabet // 23456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz
```

If you want to use your own alphabet to generate UUIDs

```swift
su.alphabet = "aaaaabcdefgh1230123"
su.uuid() // 0agee20aa1hehebcagddhedddc0d2chhab3b
```

shortuuid will automatically sort and remove duplicates from your alphabet to ensure consistency:

```swift
su.alphabet // 0123abcdefgh
```

## License

MIT
