class AEnemyShooterCharacter : AShooterCharacter {
    FTransform LHSocketT;

    const AAIController AIController;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        Mesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
        if (!IsValid(WeaponComponent)) {
            Print("EnemyShooterCharacter WeaponComponent not valid");
            return;
        }

        AsWeaponBase = Cast<AWeaponBase>(WeaponComponent.ChildActor);
        if (!IsValid(AsWeaponBase)) {
            Print("EnemyShooterCharacter WeaponComponent failed to cast");
            return;
        }

        FTransform SocketT = AsWeaponBase.Mesh.GetSocketTransform(n"LHIK",
                ERelativeTransformSpace::RTS_Component);
        LHSocketT.Location = SocketT.Rotator().RotateVector(SocketT.Location);

        AIController = Cast<AAIController>(GetController());
        if (!IsValid(AIController)) {
            Print("EnemyShooterCharacter failed to cast controller to AAIController");
            return;
        }

        WeaponComponent.SetRelativeLocation(GetGunSocketTransform(n"GripSocket").Location * -1);
    }

    FAnimState GetAnimState() override {
        FAnimState AnimState;
        AnimState.bLHIKEnabled = true;
        AnimState.bClipAttached = true;
        AnimState.LHSocketT = GetGunSocketTransform(n"LHIK");
        AnimState.LHClipT = GetGunSocketTransform(n"LHClip_new");
        AnimState.WallDistFactor = 1.f;

        return AnimState;
    }

    bool bIsDead;
    int Health;
    default Health = 100;

    UFUNCTION(BlueprintOverride)
    void AnyDamage(float Damage, const UDamageType DamageType, AController InstigatedBy,
                   AActor DamageCauser)
    {
        if (bIsDead) {
            return;
        }

        APlayerCharacter PlayerDamageCauser = Cast<APlayerCharacter>(DamageCauser);
        if (!IsValid(PlayerDamageCauser)) {
            Print("AI shot by friendly");
            return;
        }

        AIController.Blackboard.SetValueAsObject(n"TargetActor", DamageCauser);
        Health -= int(Damage);
        if (Health <= 0) {
            bIsDead = true;
            AIController.Blackboard.SetValueAsBool(n"IsDead", true);
            SpawnActor(GetClass(),
                    FVector(1900, Math::RandRange(300, 1300), 90),
                    FRotator(0, 180, 0));
            Mesh.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
            Mesh.SetSimulatePhysics(true);
            System::SetTimer(this, n"DestroySelf", 5.f, false);
        }
    }

    UFUNCTION()
    void DestroySelf() {
        DestroyActor();
    }
}