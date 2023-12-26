struct FAnimState {
    EFireMode FireMode;

    float32 ADS;
    float WallDistFactor;

    bool bIsADS;
    bool bIsSliding;
    bool bIsCrouched;
    bool bClipAttached;
    bool bLHIKEnabled;

    FTransform LHSocketT;
    FTransform LHClipT;
    FTransform LeftHandT;
    FTransform CameraT;
}