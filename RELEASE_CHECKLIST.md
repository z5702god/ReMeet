# Re:Meet Release Checklist

## Pre-Release Checklist

### Code Quality
- [ ] All features tested on physical device
- [ ] No compiler warnings
- [ ] No hardcoded API keys in source code
- [ ] All TODO comments addressed or documented

### Version Update
- [ ] Update version number in Xcode (MARKETING_VERSION)
- [ ] Update build number in Xcode (CURRENT_PROJECT_VERSION)
- [ ] Update CHANGELOG.md with release notes

### Testing
- [ ] Test login/logout flow
- [ ] Test registration with email verification
- [ ] Test password reset
- [ ] Test business card scanning (camera + photo library)
- [ ] Test contact CRUD operations
- [ ] Test search functionality
- [ ] Test Dark Mode on all screens
- [ ] Test delete account functionality
- [ ] Test on multiple iOS versions (iOS 16+)

### App Store Requirements
- [ ] Privacy policy URL is accessible
- [ ] App screenshots are up to date
- [ ] App description is accurate
- [ ] Keywords are optimized
- [ ] Support URL is valid

### Security
- [ ] API keys loaded from Config.xcconfig (not hardcoded)
- [ ] No sensitive data in logs
- [ ] HTTPS for all network requests

## Release Process

### 1. Create Release Branch
```bash
git checkout develop
git pull origin develop
git checkout -b release/v1.x.x
```

### 2. Final Testing
- Run through all checklist items above
- Fix any issues found

### 3. Merge to Main
```bash
git checkout main
git merge release/v1.x.x
git push origin main
```

### 4. Tag Release
```bash
git tag -a v1.x.x -m "Release v1.x.x - Description"
git push origin v1.x.x
```

### 5. Archive & Submit
1. In Xcode: Product → Archive
2. Distribute App → App Store Connect
3. Submit for Review in App Store Connect

### 6. Post-Release
```bash
# Merge back to develop
git checkout develop
git merge main
git push origin develop

# Delete release branch
git branch -d release/v1.x.x
```

## Hotfix Process

For urgent bug fixes on production:

```bash
# Create hotfix branch from main
git checkout main
git checkout -b hotfix/v1.x.x

# Fix the issue, then merge
git checkout main
git merge hotfix/v1.x.x
git tag -a v1.x.x -m "Hotfix: description"
git push origin main --tags

# Merge to develop
git checkout develop
git merge main
git push origin develop
```

## Version History

| Version | Date | Notes |
|---------|------|-------|
| v1.0.0 | 2025-01-15 | Initial release |
