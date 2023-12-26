class UHitMarker : UActorComponent {
    UPROPERTY()
    TSubclassOf<UHitMarkerWidget> HitMarkerWidgetClass;

    UHitMarkerWidget Widget;

    const APlayerCharacter PlayerCharacterOwner;

    FVector2D CrosshairPos;
    FVector2D TargetPos;
    bool bShouldDisplay;
    EFireMode FireMode;
    float FireRate;
    bool bIsAiming;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        PlayerCharacterOwner = Cast<APlayerCharacter>(GetOwner());
        if (!IsValid(PlayerCharacterOwner)) {
            Print("error casting BPC_HitMarker owner to APlayerCharacter");
            return;
        }
        Widget = Cast<UHitMarkerWidget>(WidgetBlueprint::CreateWidget(HitMarkerWidgetClass,
                PlayerCharacterOwner.GetLocalViewingPlayerController()));
        
        Widget.AddToViewport();
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        if (!bShouldDisplay) {
            return;
        }

        FVector IronsLoc = PlayerCharacterOwner.GetIronSightsLocation();
        APlayerController Controller = PlayerCharacterOwner.GetLocalViewingPlayerController();
        FVector2D ScreenLoc;
        Controller.ProjectWorldLocationToScreen(IronsLoc, ScreenLoc);
        int X = 0;
        int Y = 0;
        Controller.GetViewportSize(X, Y);
        FVector2D ViewportHalfSize = FVector2D(X / 2.f, Y / 2.f);
        TargetPos = ScreenLoc - ViewportHalfSize;

        if (bIsAiming) {
            if (FireMode == EFireMode::Auto) {
                CrosshairPos = Math::Vector2DInterpTo(CrosshairPos, TargetPos, FireRate, 5.0);
            } else {
                CrosshairPos = TargetPos;
            }
        } else {
            CrosshairPos = FVector2D(0, 0);
        }

        Widget.ShowHitMarker(CrosshairPos);
        bShouldDisplay = false;
    }

    void PrepHitMarker(EFireMode InFireMode, float InFireRate, bool bInIsAiming) {
        bShouldDisplay = true;
        FireMode = InFireMode;
        FireRate = InFireRate;
        bIsAiming = bInIsAiming;
    }
}