class UShooterAnimInstance : UAnimInstance {
    UPROPERTY(BlueprintReadOnly)
    EFireMode FireMode;

    UPROPERTY(BlueprintReadOnly)
    float ADS;

    UPROPERTY(BlueprintReadOnly)
    float SlideAlpha;
    default SlideAlpha = 1.f;

    UPROPERTY(BlueprintReadOnly)
    float ClipGripAlpha;

    UPROPERTY(BlueprintReadOnly)
    float LHIKAlpha;
    default LHIKAlpha = 1.0;

    UPROPERTY(BlueprintReadOnly)
    bool bIsSliding;

    UPROPERTY(BlueprintReadOnly)
    bool bIsCrouched;

    UPROPERTY(BlueprintReadOnly)
    bool bClipAttached;

    UPROPERTY(BlueprintReadOnly)
    bool bLHIKEnabled;

    UPROPERTY(BlueprintReadOnly)
    FTransform LHSocketT;

    UPROPERTY(BlueprintReadOnly)
    FTransform LHClipT;

    UPROPERTY(BlueprintReadOnly)
    FTransform CameraT;

    UPROPERTY(BlueprintReadOnly)
    FRotator AimRotation;

    UPROPERTY(BlueprintReadOnly)
    FVector Velocity;

    UPROPERTY(BlueprintReadOnly)
    float GroundSpeed;

    UPROPERTY(BlueprintReadOnly)
    float Strafe;

    UPROPERTY(BlueprintReadOnly)
    bool bShouldMove;

    UPROPERTY(BlueprintReadOnly)
    bool bIsFalling;

    UPROPERTY(BlueprintReadOnly)
    bool bIsFlying;

    UPROPERTY(BlueprintReadOnly)
    float YawOffset;

    UPROPERTY(BlueprintReadOnly)
    float WallDist;
    default WallDist = 1.f;

    UPROPERTY(BlueprintReadOnly)
    FTransform Recoil;

    FTransform RecoilT;

    AShooterCharacter Owner;

    UCharacterMovementComponent CharacterMovement;

    UFUNCTION(BlueprintOverride)
    void BlueprintInitializeAnimation()
    {
        Owner = Cast<AShooterCharacter>(GetOwningActor());
        if (!IsValid(Owner)) {
            // Print("error: ShooterAnimInstance failed to cast owner to AShooterCharacter");
            return;
        }

        CharacterMovement = Owner.CharacterMovement;
    }

    void UpdateAnimState() {
        FAnimState AnimState = Owner.GetAnimState();
        FireMode = AnimState.FireMode;
        ADS = AnimState.ADS;
        bIsSliding = AnimState.bIsSliding;
        bIsCrouched = AnimState.bIsCrouched;
        bClipAttached = AnimState.bClipAttached;
        bLHIKEnabled = AnimState.bLHIKEnabled;
        LHSocketT = AnimState.LHSocketT;
        LHClipT = AnimState.LHClipT;
        CameraT = AnimState.CameraT;
        WallDist = AnimState.WallDistFactor;
    }

    void UpdateBasicLocomotion() {
        Velocity = CharacterMovement.Velocity;
        GroundSpeed = Velocity.Size2D();
        Strafe = CalculateDirection(Velocity, Owner.GetActorRotation());
        bShouldMove = GroundSpeed > 3;
        bIsFalling = CharacterMovement.IsFalling();
        bIsFalling = CharacterMovement.IsFlying();
    }

    UFUNCTION(BlueprintOverride)
    void BlueprintUpdateAnimation(float DeltaTime)
    {
        if (!IsValid(Owner)) {
            return;
        }

        UpdateAnimState();
        UpdateBasicLocomotion();
        UpdateRecoil(DeltaTime);
        UpdateSlideAlpha();
        UpdateAimRotation();
        UpdateClipGripAlpha(DeltaTime);
        UpdateLHIKAlpha();

        // TurnInPlace();
    }

    void UpdateRecoil(float DeltaTime) {
        Recoil = Math::TInterpTo(Recoil, RecoilT, DeltaTime, 25.0);
        RecoilT = Math::TInterpTo(RecoilT, FTransform(), DeltaTime, 15.0);
    }

    UFUNCTION()
    void AddRecoil(float Multiplier) {
        FRotator RecoilRotation = FRotator();
        RecoilRotation.Roll = Math::RandRange(-2.5, -0.5);
        RecoilRotation.Pitch = Math::RandRange(-0.8, 0.8);
        RecoilRotation.Yaw = Math::RandRange(-0.8, 0.8);
        RecoilRotation *= Multiplier;
        RecoilT.Rotation = RecoilRotation.Quaternion();

        FVector RecoilLocation = FVector();
        RecoilLocation.X = Math::RandRange(-0.16, 0.16);
        RecoilLocation.Y = Math::RandRange(-1.1, -2.1);
        RecoilLocation.Z = Math::RandRange(-0.8, 0.8);
        RecoilLocation *= Multiplier;
        RecoilT.Location = RecoilLocation;
    }

    void UpdateSlideAlpha() {
        float SlideAlphaTarget = bIsSliding ? 0 : 1;
        SlideAlpha = Math::Min(Math::Lerp(SlideAlpha, SlideAlphaTarget, 0.05),
                SlideAlphaTarget);
    }

    void UpdateAimRotation() {
        FRotator Delta = Owner.GetControlRotation() - Owner.GetActorRotation();
        Delta.Normalize();
        AimRotation.Roll = Delta.Pitch * - 1.f / 3.f;
    }

    void UpdateClipGripAlpha(float DeltaTime) {
        ClipGripAlpha = Math::FInterpTo(ClipGripAlpha, bLHIKEnabled ? 1.f : 0.f,
                DeltaTime, 10.0);
    }

    void UpdateLHIKAlpha() {
        LHIKAlpha = Math::Lerp(LHIKAlpha, bClipAttached && GroundSpeed < 500 ? 1.f : 0.f, 0.12);
    }

    float ControllerYaw;
    float YawDiff;
    float AnimYaw;
    float AnimYawDiff;
    bool bTurning;

    void TurnInPlace() {
        float NewYaw = Owner.GetControlRotation().Yaw;
        YawDiff = FRotator::NormalizeAxis(NewYaw - ControllerYaw);
        ControllerYaw = NewYaw;
        YawOffset = FRotator::NormalizeAxis(YawOffset + YawDiff);

        if (bShouldMove) {
            YawOffset = 0;
            return;
        } 

        if (bTurning) {
            float CurveVal = GetCurveValue(n"TurnYaw");
            AnimYawDiff = CurveVal - AnimYaw;
            AnimYaw = CurveVal;
            YawOffset = YawOffset - (YawOffset > 0 ? AnimYawDiff : (AnimYawDiff * -1.f));

            if (Math::IsNearlyEqual(AnimYaw, 0.f, 0.001)) {
                bTurning = false;
            }
        } else {
            if (Math::Abs(YawOffset) > 90.f) {
                AnimYaw = -90.f;
                bTurning = true;
            }
        }
    }
}