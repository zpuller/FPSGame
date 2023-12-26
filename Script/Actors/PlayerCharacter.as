
class APlayerCharacter : AShooterCharacter {
    UPROPERTY(DefaultComponent, Attach = CharacterMesh0, AttachSocket = neck_02)
    USpringArmComponent CameraBoom;

    UPROPERTY(DefaultComponent, Attach = CameraBoom)
    UCameraComponent FollowCamera;

    UPROPERTY(DefaultComponent, Attach = FollowCamera)
    USceneComponent Offset;

    UPROPERTY(DefaultComponent)
    UPlayerActions PlayerActions;

    UPROPERTY(DefaultComponent)
    UMotionWarpingComponent MotionWarping;

    UPROPERTY(DefaultComponent)
    UCharacterVaulting CharacterVaulting;

    UPROPERTY(DefaultComponent)
    UInventoryComponent Inventory;

    UPROPERTY(DefaultComponent)
    UPlayerStats PlayerStats;

    UPROPERTY(DefaultComponent)
    UHitMarker HitMarker;

    FOnTimelineFloat ADSTimelineCB;

    UPROPERTY(DefaultComponent)
    UTimelineComponent ADSTimeline;

    FOnTimelineFloat RecoilTimelineCB;

    UPROPERTY(DefaultComponent)
    UTimelineComponent RecoilTimeline;

    UPROPERTY()
    UAnimMontage SwitchWeaponMontage;

    UPROPERTY()
    UCurveFloat ADSCurve;

    UPROPERTY()
    UCurveFloat RecoilCurve;

    UPROPERTY()
    TSubclassOf<UUserWidget> CrosshairWidgetClass;

    UUserWidget CrosshairWidget;

    UShooterAnimInstance AnimInstance;

    FAnimState AnimState;
    default AnimState.bLHIKEnabled = true;
    default AnimState.bClipAttached = true;

    bool bIsAimInputActive;
    bool bIsFireInputActive;

    float RecoilAmount;

    FTimerHandle FireTimerHandle;

    FOnSoftClassLoaded Callback = FOnSoftClassLoaded(this, n"OnWeaponLoaded");

    FAnimState GetAnimState() override {
        AnimState.FireMode = Inventory.GetFireMode();
        AnimState.bIsADS = bIsAimInputActive;
        AnimState.bIsSliding = PlayerActions.IsActionActive(EPlayerAction::Slide);
        AnimState.bIsCrouched = PlayerActions.IsActionActive(EPlayerAction::Crouch);
        AnimState.LHSocketT = GetGunSocketTransform(n"LHIK");
        AnimState.LHClipT = GetGunSocketTransform(n"LHClip_new");
        AnimState.LeftHandT = Mesh.GetSocketTransform(n"ClipSocket");
        return AnimState;
    }

    UFUNCTION()
    void OnWeaponLoaded(UClass WeaponClass) {
        WeaponComponent.SetChildActorClass(WeaponClass);
        AsWeaponBase = Cast<AWeaponBase>(WeaponComponent.ChildActor);

        WeaponComponent.SetRelativeLocation(GetGunSocketTransform(n"GripSocket").Location * -1);
    }

    void EquipItem() {
        Inventory.EquippedItem(Callback);
    }

    float MinWallDist;
    default MinWallDist = 80.f;
    float MaxWallDist;
    default MaxWallDist = 150.f;
    float WallClipFixInterval;
    default WallClipFixInterval = 0.02;

    UFUNCTION()
    void WallClipFix() {
        FVector Start = GetActorLocation() + GetActorForwardVector() * MinWallDist +
                (GetActorUpVector() * 40.f);
        FVector End = GetActorLocation() + GetActorForwardVector() * MaxWallDist +
                (GetActorUpVector() * 40.f);
        FHitResult OutHit;
        bool bDidHit = System::LineTraceSingle(Start, End, ETraceTypeQuery::Visibility,
                false, TArray<AActor>(), EDrawDebugTrace::None,
                OutHit, true);

        float TargetFactor = 1.f;
        if (bDidHit) {
            TargetFactor = (OutHit.Location.Distance(GetActorLocation()) - MinWallDist) /
                    (MaxWallDist - MinWallDist);
        }

        float InterpSpeed = bDidHit ? 20.f : 40.f;
        AnimState.WallDistFactor = Math::FInterpTo(AnimState.WallDistFactor, TargetFactor,
                WallClipFixInterval, InterpSpeed);
    }

    UFUNCTION(BlueprintOverride)
    void BeginPlay() {
        AnimInstance = Cast<UShooterAnimInstance>(Mesh.GetAnimInstance());
        if (!IsValid(AnimInstance)) {
            Print("failed to get/cast APlayerCharacter's UShooterAnimInstance");
        }

        ADSTimelineCB.BindUFunction(this, n"UpdateADS");
        ADSTimeline.AddInterpFloat(ADSCurve, ADSTimelineCB);
        RecoilTimelineCB.BindUFunction(this, n"UpdateRecoil");
        RecoilTimeline.AddInterpFloat(RecoilCurve, RecoilTimelineCB);

        EquipItem();

        CrosshairWidget = Cast<UUserWidget>(WidgetBlueprint::CreateWidget(CrosshairWidgetClass,
                GetLocalViewingPlayerController()));
        
        CrosshairWidget.AddToViewport();

        System::SetTimer(this, n"UpdateADSPose", 0.02, true);
        System::SetTimer(this, n"WallClipFix", WallClipFixInterval, true);
    }

    UFUNCTION()
    void UpdateADSPose() {
        FTransform GripSocketT = GetGunSocketTransform(n"GripSocket");
        FTransform IronSightsT = GetGunSocketTransform(n"IronSights");
        FTransform OffsetWorldT = Offset.GetWorldTransform();
        FVector CameraWorldLocation = OffsetWorldT.Rotation.RotateVector(IronSightsT.Location) * -1 +
                OffsetWorldT.Rotation.RotateVector(GripSocketT.Location) + OffsetWorldT.Location;
        
        FVector OutLoc;
        FRotator OutRot;
        Mesh.TransformToBoneSpace(n"neck_02", CameraWorldLocation, OffsetWorldT.Rotator(), 
                OutLoc, OutRot); 

        AnimState.CameraT = FTransform(OutRot.Quaternion(), OutLoc);
    }

    void StopCrouch() {
        PlayerActions.StopAction(EPlayerAction::Slide);
        PlayerActions.StopAction(EPlayerAction::Crouch);
        CharacterMovement.MaxWalkSpeed = 300;
    }

    UFUNCTION()
    void StopSlide() {
        PlayerActions.StopAction(EPlayerAction::Slide);
        if (PlayerActions.TryAction(EPlayerAction::Crouch)) {
            CharacterMovement.MaxWalkSpeed = 200;
        }
    }

    UFUNCTION()
    void ToggleCrouch() {
        if (PlayerActions.IsActionActive(EPlayerAction::Crouch)) {
            StopCrouch();
        } else {
            if (PlayerActions.IsActionActive(EPlayerAction::Sprint)) {
                PlayerActions.StopAction(EPlayerAction::Sprint);
                if (PlayerActions.TryAction(EPlayerAction::Slide)) {
                    System::SetTimer(this, n"StopSlide", 0.7, false);
                }
            } else {
                StopSlide();
            }
        }
    }

    UFUNCTION()
    void StartSprint() {
        if (PlayerActions.TryAction(EPlayerAction::Sprint)) {
            PlayerActions.StopAction(EPlayerAction::Crouch);
            CharacterMovement.MaxWalkSpeed = 600;
        }
    }

    UFUNCTION()
    void StopSprint() {
        PlayerActions.StopAction(EPlayerAction::Sprint);
        CharacterMovement.MaxWalkSpeed = 300;
        CheckAim();
    }

    void TryJump() {
        if (PlayerActions.IsActionActive(EPlayerAction::Crouch)) {
            StopCrouch();
        } else {
            if (PlayerActions.IsActionActive(EPlayerAction::Slide)) {
                StopSlide();
            } else {
                if (PlayerActions.TryAction(EPlayerAction::Jump)) {
                    Jump();
                }
            }
        }
    }

    void FailVault() {
        PlayerActions.StopAction(EPlayerAction::Vault);
        TryJump();
    }

    UFUNCTION()
    void OnVaultComplete(UAnimMontage Montage, bool bIsInterrupted) {
        CharacterMovement.SetMovementMode(EMovementMode::MOVE_Walking);
        SetActorEnableCollision(true);
        CharacterVaulting.VaultInfo.bCanWarp = false;
        CharacterVaulting.VaultInfo.LandPos = FVector(0, 0, 20000);
        PlayerActions.StopAction(EPlayerAction::Vault);
        CheckAim();
        CheckFiring();
    }

    void VaultAnim() {
        float LandZ = CharacterVaulting.VaultInfo.LandPos.Z;
        float MeshZ = Mesh.GetWorldLocation().Z;
        if (CharacterVaulting.VaultInfo.bCanWarp &&
                InRange(LandZ, MeshZ - 50, MeshZ + 120)) {

            CharacterMovement.SetMovementMode(EMovementMode::MOVE_Flying);
            SetActorEnableCollision(false);

            MotionWarping.AddOrUpdateWarpTargetFromLocationAndRotation(n"VaultStart",
            CharacterVaulting.VaultInfo.StartPos, GetActorRotation());

            MotionWarping.AddOrUpdateWarpTargetFromLocationAndRotation(n"VaultMiddle",
            CharacterVaulting.VaultInfo.MiddlePos, GetActorRotation());

            FVector LandPos = CharacterVaulting.VaultInfo.bShortVault ?
                    CharacterVaulting.VaultInfo.ShortLandPos :
                    CharacterVaulting.VaultInfo.LandPos;
            MotionWarping.AddOrUpdateWarpTargetFromLocationAndRotation(n"VaultLand", LandPos,
            GetActorRotation());

            UAnimMontage MontageToPlay = CharacterVaulting.VaultInfo.bShortVault ?
                    CharacterVaulting.ShortVaultMontage : CharacterVaulting.VaultMontage;

            Mesh.GetAnimInstance().OnMontageEnded.Clear();
            Mesh.GetAnimInstance().OnMontageEnded.AddUFunction(this, n"OnVaultComplete");
            Mesh.GetAnimInstance().Montage_Play(MontageToPlay);
        } else {
            FailVault();
        }
    }

    UFUNCTION()
    void VaultJump() {
        if (PlayerActions.TryAction(EPlayerAction::Vault)) {
            CharacterVaulting.VaultInfo.bCanWarp = false;
            if (CharacterVaulting.EvaluateVault()) {
                VaultAnim();
            }
            if (!CharacterVaulting.VaultInfo.bCanWarp) {
                PlayerActions.StopAction(EPlayerAction::Vault);
                TryJump();
            }
        } else {
            FailVault();
        }
    }

    UFUNCTION()
    void CompleteJump() {
        PlayerActions.StopAction(EPlayerAction::Jump);
        StopJumping();
    }

    UFUNCTION()
    void UpdateADS(float32 X) {
        AnimState.ADS = X;

        // TODO: Follow Camera - this is problematic due to basing RHIK off
        // camera position, so we probably need to adjust the offset correspondingly
        // FollowCamera.SetRelativeLocation(FVector(10.f, 0.f, 0.f) * (1.f + X));
    }


    UFUNCTION()
    void UpdateRecoil(float32 X) {
        float RecoilTimelineFactor = Math::Lerp(0, RecoilAmount, X);
        AddControllerPitchInput(RecoilTimelineFactor  * (bIsAimInputActive ? 0.5 : 1) * -1);
        float YawMagnitude = RecoilTimelineFactor / (bIsAimInputActive ? 10 : 4);
        AddControllerYawInput(YawMagnitude * (Math::RandBool() ? 1 : -1));
    }

    void StartAim() {
        if (PlayerActions.TryAction(EPlayerAction::Aim)) {
            CrosshairWidget.RemoveFromParent();
            ADSTimeline.PlayFromStart();
        }
    }

    void StopAim() {
        PlayerActions.StopAction(EPlayerAction::Aim);
        CrosshairWidget.AddToViewport();
        ADSTimeline.Reverse();
    }

    void CheckAim() {
        if (bIsAimInputActive) {
            StartAim();
        }
    }

    UFUNCTION()
    void AimActionStarted() {
        bIsAimInputActive = true;
        StartAim();
    }

    UFUNCTION()
    void AimActionStopped() {
        bIsAimInputActive = false;
        StopAim();
    }

    void UpdateCrosshairPos() {
        HitMarker.PrepHitMarker(Inventory.GetFireMode(),
                Inventory.GetFireRate(), bIsAimInputActive);
    }

    UPROPERTY() 
    UParticleSystem MetalDecalParticle;

    UPROPERTY() 
    UClass BloodDecalClass;

    UPROPERTY()
    float HipFireSpread;
    default HipFireSpread = 5000;

    void ShootRay() {
        FVector Start = FollowCamera.GetWorldLocation();
        FVector Spread = FVector();
        if (!bIsAimInputActive) {
            Spread = FollowCamera.GetRightVector() * HipFireSpread *
                    Math::RandRange(-1.f, 1.f);
            Spread += FollowCamera.GetUpVector() * HipFireSpread *
                    Math::RandRange(-1.f, 1.f);
        }
        FVector End = Start + (FollowCamera.GetForwardVector() * 50000) + Spread;
        FHitResult OutHit;
        bool bDidHit = System::LineTraceSingle(Start, End, ETraceTypeQuery::Camera, false,
                TArray<AActor>(), EDrawDebugTrace::None, OutHit, true);
        if (!bDidHit) {
            AsWeaponBase.ImpactVolume = 0.f;
            return;
        } 

        AActor HitActor = OutHit.Actor;
        FVector HitLocation = OutHit.Location;

        // FVector HitLoc = OutHit.Location;
        Gameplay::ApplyDamage(HitActor, Inventory.GetDamage(),
                GetController(), this, nullptr);

        if (!IsValid(HitActor)) {
            return;
        }

        if (HitActor.ActorHasTag(n"Metal")) {
            Gameplay::SpawnEmitterAtLocation(MetalDecalParticle, HitLocation);
            AsWeaponBase.ImpactVolume = 0.f;
            return;
        }
        
        if (HitActor.ActorHasTag(n"Flesh")) {
            TArray<AActor> ActorsToIgnore = TArray<AActor>();
            ActorsToIgnore.Add(HitActor);
            bool bInnerDidHit = System::LineTraceSingle(Start, End, ETraceTypeQuery::Camera,
                    false, ActorsToIgnore,
                    EDrawDebugTrace::None, OutHit, true);
            if (!bInnerDidHit) {
                AsWeaponBase.ImpactVolume = 0.f;
                return;
            }
            SpawnActor(BloodDecalClass, OutHit.Location,
                    OutHit.Normal.ToOrientationRotator());
            AsWeaponBase.ImpactVolume = 0.5;
            UpdateCrosshairPos();
            return;
        }

        AsWeaponBase.ImpactVolume = 0.f;
    }

    void ControllerRecoil(float NewRecoilAmount) {
        RecoilAmount = NewRecoilAmount;
        RecoilTimeline.PlayFromStart();
    }

    UFUNCTION()
    void FireOneBullet() {
        if (Inventory.GetAmmo() <= 0) {
            return;
        }

        ShootRay();
        AsWeaponBase.Fire();
        Inventory.DecrementAmmo();
        AnimInstance.AddRecoil(1.5);
        ControllerRecoil(0.2);
    }

    void StartFiring() {
        if (!PlayerActions.TryAction(EPlayerAction::Fire)) {
            return;
        }

        switch (Inventory.GetFireMode()) {
            case EFireMode::Auto:
                FireTimerHandle = System::SetTimer(this, n"FireOneBullet",
                        Inventory.GetFireRate(), true);
                break;

            case EFireMode::SemiAuto:
                break;

            default:
                Print("warn: default firing mode switch case");
        }

        FireOneBullet();
    }

    void StopFiring() {
        PlayerActions.StopAction(EPlayerAction::Fire);
        System::ClearAndInvalidateTimerHandle(FireTimerHandle);
    }

    void CheckFiring() {
        if (bIsFireInputActive) {
            StartFiring();
        }
    }

    UFUNCTION()
    void FireActionStarted() {
        bIsFireInputActive = true;
        StartFiring();
    }

    UFUNCTION()
    void FireActionStopped() {
        bIsFireInputActive = false;
        StopFiring();
    }

    UFUNCTION()
    void OnSwitchWeaponsComplete(UAnimMontage Montage, bool bIsInterrupted) {
        PlayerActions.StopAction(EPlayerAction::SwitchWeapons);
        CheckAim();
        CheckFiring();
    }

    UFUNCTION()
    void SwitchWeaponsImpl() {
        Inventory.SwitchWeapon();
        EquipItem();
    }

    UFUNCTION()
    void SwitchWeapons() {
        if (!PlayerActions.TryAction(EPlayerAction::SwitchWeapons)) {
            return;
        }

        StopFiring();
        System::SetTimer(this, n"SwitchWeaponsImpl", 0.5, false);

        Mesh.GetAnimInstance().OnMontageEnded.Clear();
        Mesh.GetAnimInstance().OnMontageEnded.AddUFunction(this, n"OnSwitchWeaponsComplete");
        Mesh.GetAnimInstance().Montage_Play(SwitchWeaponMontage);
    }

    UFUNCTION()
    void SetClipAttached(bool bAttached) {
        AnimState.bClipAttached = bAttached;
    }

    UFUNCTION()
    bool GetClipAttached() {
        return AnimState.bClipAttached;
    }

    UFUNCTION()
    void FinishReload() {
        AnimState.bLHIKEnabled = true;
        PlayerActions.StopAction(EPlayerAction::Reload);
        CheckFiring();
    }

    UFUNCTION()
    void Reload() {
        if (!Inventory.CanReload() || !PlayerActions.TryAction(EPlayerAction::Reload)) {
            return;
        }

        StopFiring();
        AnimState.bLHIKEnabled = false;
        float32 Duration = PlayAnimMontage(AsWeaponBase.GetCharacterReloadMontage(bIsAimInputActive));
        System::SetTimer(Inventory, n"Reload", Duration, false);
        System::SetTimer(this, n"FinishReload", Duration - 0.2, false);
        AsWeaponBase.Reload(bIsAimInputActive);
    }

    UFUNCTION(BlueprintOverride)
    void AnyDamage(float Damage, const UDamageType DamageType, AController InstigatedBy,
                   AActor DamageCauser)
    {
        bool bIsDead = PlayerStats.ReduceHealth(Math::TruncToInt(Damage));
        if (bIsDead) {
            Gameplay::OpenLevel(n"ThirdPersonMap", true);
        }
    }

    FVector GetIronSightsLocation() const {
        return AsWeaponBase.Mesh.GetSocketLocation(n"IronSights");
    }
}