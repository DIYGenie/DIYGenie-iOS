# Apply the latest DIY Genie changes without `git pull`

If Xcode shows an error like:

```
error: Entry 'DIYGenieApp/Source/Services/ProjectsService.swift' not uptodate. Cannot merge.
fatal: Could not reset index file to revision 'HEAD'.
```

that means there are local edits that conflict with the new files. Follow these steps in **Terminal** to safely update:

1. Open Terminal and `cd` into your project folder (the one that contains `DIYGenieApp.xcodeproj`).
2. Check for local edits:
   ```bash
   git status
   ```
   *If you see files listed under "Changes not staged for commit", continue.*
3. Save those edits aside (optional but recommended):
   ```bash
   git stash push -m "backup-before-diygenie-update"
   ```
4. Reset the tracked files to the last commit so the new files can be copied in:
   ```bash
   git reset --hard HEAD
   ```
5. Now copy the updated files from this handoff into your project (drag the Swift files from Finder or right-click → **Add Files to "DIYGenieApp"…** in Xcode). The files that changed in this update are:
   - `DIYGenieApp/Source/Models/Project.swift`
   - `DIYGenieApp/Source/Models/UserSession.swift`
   - `DIYGenieApp/Source/Services/ProjectsService.swift`
   - `DIYGenieApp/Source/Views/NewProjectView.swift`
   - `DIYGenieApp/Source/Views/Helpers/ARRoomPlanSheet.swift`

   The two helper files that no longer exist should also be removed from Xcode:
   - `LocalPlanGenerator.swift`
   - `LocalProjectsStore.swift`

6. Clean the build folder in Xcode (**Shift+Cmd+K**) and build again (**Cmd+R**).
7. If you stashed edits in step 3 and need them back, run:
   ```bash
   git stash pop
   ```
   Resolve any conflicts by keeping the new versions of the DIY Genie files.

This flow avoids `git pull` and gets your local project in sync with the working build from this handoff.
