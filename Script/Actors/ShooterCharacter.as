class AShooterCharacter : ACharacter {
    UPROPERTY(DefaultComponent, Attach = CharacterMesh0, AttachSocket = WeaponSocket)
    UChildActorComponent WeaponComponent;

    UPROPERTY(BlueprintReadOnly)
    AWeaponBase AsWeaponBase;

    void GetADSImpl(float&out ADS, bool&out bIsADS) const {}

    UFUNCTION()
    FTransform GetLeftHandT() const {
        return Mesh.GetSocketTransform(n"ClipSocket");
    }

    FAnimState GetAnimState() {
        FAnimState State;
        return State;
    }

    FTransform GetGunSocketTransform(FName SocketName) const {
        if (!IsValid(AsWeaponBase)) {
            return FTransform();
        }

        FTransform SocketTComponent = AsWeaponBase.Mesh.GetSocketTransform(
                SocketName, ERelativeTransformSpace::RTS_Component);

        return FTransform(FQuat(), SocketTComponent.Rotation.RotateVector(SocketTComponent.Location));
    }
}