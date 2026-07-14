# Phase 1.1 — Asset Cleanup Script
# Moves unused assets to _archive\ folder. Safe to rollback by moving back.

$root = "d:\GameDev\hideandseek"
$archive = "$root\_archive"

Write-Host "=== Phase 1.1: Asset Cleanup ===" -ForegroundColor Cyan
Write-Host "Root: $root"
Write-Host "Archive: $archive"
Write-Host ""

# ============================================================
# STEP 1: Create archive folder structure
# ============================================================
Write-Host "[1/8] Creating archive folder structure..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "$archive\POLYGON_SciFi_Space_models" | Out-Null
New-Item -ItemType Directory -Force -Path "$archive\POLYGON_SciFi_Space_textures" | Out-Null
New-Item -ItemType Directory -Force -Path "$archive\POLYGON_SciFi_Space_materials" | Out-Null
New-Item -ItemType Directory -Force -Path "$archive\tscn_separate_unused" | Out-Null
New-Item -ItemType Directory -Force -Path "$archive\animations_robots_unused" | Out-Null
New-Item -ItemType Directory -Force -Path "$archive\assets_characters_unused" | Out-Null
New-Item -ItemType Directory -Force -Path "$archive\scenes_unused" | Out-Null
Write-Host "   Archive folders created." -ForegroundColor Green

# ============================================================
# STEP 2: Move models/ FBX source folder (~94 MB)
# ============================================================
Write-Host "[2/8] Archiving models/ folder (~94 MB)..." -ForegroundColor Yellow
$modelsPath = "$root\SyntySciFiSpace\POLYGON_SciFi_Space\models"
if (Test-Path $modelsPath) {
    Move-Item -Path $modelsPath -Destination "$archive\POLYGON_SciFi_Space_models" -Force
    Write-Host "   models/ archived." -ForegroundColor Green
} else {
    Write-Host "   models/ not found, skipping." -ForegroundColor DarkGray
}

# ============================================================
# STEP 3: Archive unused tscn_separate files (~290 MB)
# Only 36 files are kept — all others move to archive
# ============================================================
Write-Host "[3/8] Archiving unused tscn_separate files (~290 MB)..." -ForegroundColor Yellow

$tscnDir = "$root\SyntySciFiSpace\POLYGON_SciFi_Space\meshes\tscn_separate"

$keepFiles = @(
    "SM_Bld_Bridge_Ceiling_01.tscn",
    "SM_Bld_Bridge_Console_01.tscn",
    "SM_Bld_Bridge_Floor_01.tscn",
    "SM_Bld_Bridge_Walls_01.tscn",
    "SM_Bld_Bridge_Walls_Glass_01.tscn",
    "SM_Bld_Ceiling_01.tscn",
    "SM_Bld_Ceiling_02.tscn",
    "SM_Bld_Ceiling_03.tscn",
    "SM_Bld_Ceiling_Pipes_Straight_01.tscn",
    "SM_Bld_Floor_02.tscn",
    "SM_Bld_Floor_04.tscn",
    "SM_Bld_Wall_01.tscn",
    "SM_Bld_Wall_Corner_Pillar_01.tscn",
    "SM_Bld_Wall_Doorframe_01.tscn",
    "SM_Bld_Wall_Doorframe_03.tscn",
    "SM_Bld_Wall_Doorframe_04.tscn",
    "SM_Bld_Wall_Pillar_01.tscn",
    "SM_Bld_Wall_Pillar_04.tscn",
    "SM_Prop_AirVent_Small_01.tscn",
    "SM_Prop_Battery_01.tscn",
    "SM_Prop_Cart_Filled_01.tscn",
    "SM_Prop_Chr_Male_Cryo_01.tscn",
    "SM_Prop_Crate_Wide_01.tscn",
    "SM_Prop_CryoBed_01.tscn",
    "SM_Prop_DeadZub_01.tscn",
    "SM_Prop_Detail_CeilingBox_03.tscn",
    "SM_Prop_Detail_Handle_02.tscn",
    "SM_Prop_Detail_Machine_01.tscn",
    "SM_Prop_Detail_Pipes_01.tscn",
    "SM_Prop_Detail_Pipes_02.tscn",
    "SM_Prop_Detail_Vent_01.tscn",
    "SM_Prop_Engine_Construction_01.tscn",
    "SM_Prop_Ladder_01.tscn",
    "SM_Prop_MapTable_01.tscn",
    "SM_Prop_Medical_Tube_01.tscn",
    "SM_Prop_Medical_Tube_Glass_01.tscn"
)

if (Test-Path $tscnDir) {
    # Move Characters and FX_Meshes subdirectories entirely
    $charsSubDir = "$tscnDir\Characters"
    if (Test-Path $charsSubDir) {
        Move-Item -Path $charsSubDir -Destination "$archive\tscn_separate_unused\Characters" -Force
        Write-Host "   Characters/ subdirectory archived." -ForegroundColor Green
    }
    $fxSubDir = "$tscnDir\FX_Meshes"
    if (Test-Path $fxSubDir) {
        Move-Item -Path $fxSubDir -Destination "$archive\tscn_separate_unused\FX_Meshes" -Force
        Write-Host "   FX_Meshes/ subdirectory archived." -ForegroundColor Green
    }

    # Move all root-level tscn files that are NOT in the keep list
    $allTscnFiles = Get-ChildItem -Path $tscnDir -Filter "*.tscn" -File
    $movedCount = 0
    $skippedCount = 0
    foreach ($f in $allTscnFiles) {
        if ($f.Name -in $keepFiles) {
            $skippedCount++
        } else {
            Move-Item -Path $f.FullName -Destination "$archive\tscn_separate_unused\$($f.Name)" -Force
            $movedCount++
        }
    }
    Write-Host "   Archived $movedCount unused tscn files. Kept $skippedCount used files." -ForegroundColor Green
} else {
    Write-Host "   tscn_separate/ not found, skipping." -ForegroundColor DarkGray
}

# ============================================================
# STEP 4: Archive unused textures (~45 MB)
# Keep only 3 referenced textures (+ their .import files)
# ============================================================
Write-Host "[4/8] Archiving unused textures (~45 MB)..." -ForegroundColor Yellow

$texDir = "$root\SyntySciFiSpace\POLYGON_SciFi_Space\textures"
$keepTextures = @(
    "PolygonSciFiCity_01_Normals.png",
    "PolygonSciFiCity_01_Normals.png.import",
    "PolygonSciFiSpace_01_Emissive.png",
    "PolygonSciFiSpace_01_Emissive.png.import",
    "PolygonSciFiSpace_Texture_01_A.png",
    "PolygonSciFiSpace_Texture_01_A.png.import"
)

if (Test-Path $texDir) {
    $allTexFiles = Get-ChildItem -Path $texDir -File
    $movedTex = 0
    $keptTex = 0
    foreach ($f in $allTexFiles) {
        if ($f.Name -in $keepTextures) {
            $keptTex++
        } else {
            Move-Item -Path $f.FullName -Destination "$archive\POLYGON_SciFi_Space_textures\$($f.Name)" -Force
            $movedTex++
        }
    }
    Write-Host "   Archived $movedTex unused texture files. Kept $keptTex used files." -ForegroundColor Green
} else {
    Write-Host "   textures/ not found, skipping." -ForegroundColor DarkGray
}

# ============================================================
# STEP 5: Archive materials folder (~0.2 MB)
# ============================================================
Write-Host "[5/8] Archiving materials/ folder..." -ForegroundColor Yellow
$matDir = "$root\SyntySciFiSpace\POLYGON_SciFi_Space\materials"
if (Test-Path $matDir) {
    Move-Item -Path $matDir -Destination "$archive\POLYGON_SciFi_Space_materials" -Force
    Write-Host "   materials/ archived." -ForegroundColor Green
} else {
    Write-Host "   materials/ not found, skipping." -ForegroundColor DarkGray
}

# ============================================================
# STEP 6: Archive unused robot animation FBX files (~5 MB)
# ============================================================
Write-Host "[6/8] Archiving unused robot animations (~5 MB)..." -ForegroundColor Yellow

$robotDir = "$root\assets\animations\robots"
$unusedRobotAnims = @(
    "Cross Punch (1).fbx",
    "Cross Punch (1).fbx.import",
    "Cross Punch.fbx",
    "Cross Punch.fbx.import",
    "frantic look.fbx",
    "frantic look.fbx.import",
    "Kiss.fbx",
    "Kiss.fbx.import",
    "Look Around.fbx",
    "Look Around.fbx.import",
    "Looking (1).fbx",
    "Looking (1).fbx.import",
    "Looking (2).fbx",
    "Looking (2).fbx.import",
    "Looking.fbx",
    "Looking.fbx.import",
    "Unarmed Walk Forward.fbx",
    "Unarmed Walk Forward.fbx.import",
    "Walk.fbx",
    "Walk.fbx.import",
    "Wheelbarrow Idle.fbx",
    "Wheelbarrow Idle.fbx.import",
    "Working On Device.fbx",
    "Working On Device.fbx.import"
)

if (Test-Path $robotDir) {
    $movedRobot = 0
    foreach ($fileName in $unusedRobotAnims) {
        $filePath = "$robotDir\$fileName"
        if (Test-Path $filePath) {
            Move-Item -Path $filePath -Destination "$archive\animations_robots_unused\$fileName" -Force
            $movedRobot++
        }
    }
    Write-Host "   Archived $movedRobot robot animation files." -ForegroundColor Green
} else {
    Write-Host "   robots/ animation dir not found, skipping." -ForegroundColor DarkGray
}

# ============================================================
# STEP 7: Archive unused character assets (~1.6 MB)
# ============================================================
Write-Host "[7/8] Archiving unused character assets (~1.6 MB)..." -ForegroundColor Yellow

$charDir = "$root\assets\characters"
$unusedCharAssets = @(
    "Robot.tscn",
    "Characters.fbx.import",
    "polygonDungeon_Characters.fbx.import"
)

if (Test-Path $charDir) {
    $movedChar = 0
    foreach ($fileName in $unusedCharAssets) {
        $filePath = "$charDir\$fileName"
        if (Test-Path $filePath) {
            Move-Item -Path $filePath -Destination "$archive\assets_characters_unused\$fileName" -Force
            $movedChar++
        }
    }
    Write-Host "   Archived $movedChar character asset files." -ForegroundColor Green
} else {
    Write-Host "   characters/ not found, skipping." -ForegroundColor DarkGray
}

# ============================================================
# STEP 8: Archive unused level scenes
# ============================================================
Write-Host "[8/8] Archiving unused level scenes..." -ForegroundColor Yellow

$unusedScenes = @(
    "$root\scenes\levels\level_3_engine_room.tscn",
    "$root\scenes\levels\level_test.tscn"
)

$movedScenes = 0
foreach ($scenePath in $unusedScenes) {
    if (Test-Path $scenePath) {
        $fileName = [System.IO.Path]::GetFileName($scenePath)
        Move-Item -Path $scenePath -Destination "$archive\scenes_unused\$fileName" -Force
        $movedScenes++
    }
}
Write-Host "   Archived $movedScenes level scene files." -ForegroundColor Green

# ============================================================
# SUMMARY
# ============================================================
Write-Host ""
Write-Host "=== Cleanup Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Measuring post-cleanup project size (excluding archive and .godot cache)..." -ForegroundColor Yellow
$postSize = Get-ChildItem -Recurse -File $root |
    Where-Object {
        $_.FullName -notmatch [regex]::Escape("$root\.git") -and
        $_.FullName -notmatch [regex]::Escape("$root\_archive") -and
        $_.FullName -notmatch [regex]::Escape("$root\.godot")
    } |
    Measure-Object -Property Length -Sum
$postSizeMB = [math]::Round($postSize.Sum / 1MB, 1)
Write-Host "Post-cleanup source asset size: $postSizeMB MB" -ForegroundColor Green
Write-Host ""
Write-Host "Archive folder is at: $archive" -ForegroundColor Cyan
Write-Host "To rollback: move contents of _archive\ back to their original locations and reopen Godot." -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Open Godot and check for missing resource errors"
Write-Host "  2. Play Level 1 and Level 2 to confirm they load correctly"
Write-Host "  3. Run: powershell -ExecutionPolicy Bypass -File .\run_tests.ps1"
