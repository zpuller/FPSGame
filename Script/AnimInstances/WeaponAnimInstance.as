class UWeaponAnimInstance : UAnimInstance {
    AWeaponBase Weapon;
    AShooterCharacter Shooter;

    UPROPERTY(BlueprintReadOnly)
    bool bClipAttached;

    UPROPERTY(BlueprintReadOnly)
    FTransform LeftHandT;

    UFUNCTION(BlueprintOverride)
    void BlueprintInitializeAnimation()
    {
        Weapon = Cast<AWeaponBase>(GetOwningActor());
        if (!IsValid(Weapon)) {
            return;
        }
        Shooter = Cast<AShooterCharacter>(Weapon.GetParentActor());
    }

    UFUNCTION(BlueprintOverride)
    void BlueprintUpdateAnimation(float DeltaTimeX)
    {
        if (!IsValid(Weapon)) {
            return;
        }

        bClipAttached = Weapon.GetClipAttached();
        LeftHandT =  Shooter.GetLeftHandT();
    }
}