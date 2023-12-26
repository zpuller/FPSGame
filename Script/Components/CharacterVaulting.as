struct FVaultInfo {
    bool bCanWarp;
    bool bShortVault;
    FVector StartPos;
    FVector MiddlePos;
    FVector LandPos;
    FVector ShortLandPos;
}

class UCharacterVaulting : UActorComponent {
    UPROPERTY()
    UAnimMontage VaultMontage;

    UPROPERTY()
    UAnimMontage ShortVaultMontage;

    FVaultInfo VaultInfo;
    const ACharacter Character;
    const EDrawDebugTrace TraceDebugDrawing = EDrawDebugTrace::None;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        Character = Cast<ACharacter>(GetOwner());
    }

    bool SphereTrace(FVector Start, FVector End, FHitResult&out OutHit) {
        return System::SphereTraceSingle(Start, End, 5.0, ETraceTypeQuery::Visibility,
        false, TArray<AActor>(), TraceDebugDrawing, OutHit,
        true);
    }

    bool LineTrace(FVector Start, FVector End, FHitResult&out OutHit) {
        return System::LineTraceSingle(Start, End, ETraceTypeQuery::Visibility, false,
        TArray<AActor>(), TraceDebugDrawing, OutHit, true);
    }

    void EvaluateVaultTrajectory(FVector HitLocation) {
        for (int i = 0; i < 6; ++i) {
            FVector Start = HitLocation + FVector(0, 0, 100) +
                    (Character.GetActorForwardVector() * (50 * i + 1));
            FVector End = Start - FVector(0, 0, 100);
            FHitResult OutHit;
            bool DidHit = SphereTrace(Start, End, OutHit);
            if (DidHit && i < 5) {
                if (i == 0) {
                    VaultInfo.StartPos = OutHit.Location;
                }
                VaultInfo.MiddlePos = OutHit.Location;
                VaultInfo.bCanWarp = true;
                if (i == 3) {
                    VaultInfo.ShortLandPos = OutHit.Location;
                }
            } else {
                FHitResult OutHitLand;
                FVector LandTraceStart = OutHit.TraceStart + (Character.GetActorForwardVector() * 80);
                FVector LandTraceEnd = LandTraceStart - FVector(0, 0, 1000);
                if (LineTrace(LandTraceStart, LandTraceEnd, OutHitLand)) {
                    VaultInfo.LandPos = OutHitLand.Location;
                    VaultInfo.bShortVault = OutHitLand.Location.Z > Character.GetActorLocation().Z - 70;
                    break;
                }
            }
        }
    }

    bool EvaluateVault() {
        for (int i = 0; i < 3; ++i) {
            FVector Basis = Character.GetActorLocation() + FVector(0, 0, i * 30) + FVector(0, 0, -50);
            FVector Start = Basis + (Character.GetActorForwardVector() * -20);
            FVector End = Basis + (Character.GetActorForwardVector() * 180);
            FHitResult OutHit;
            bool DidHit = SphereTrace(Start, End, OutHit);
            if (DidHit) {
                EvaluateVaultTrajectory(OutHit.Location);
                return true;
            }
        }
        return false;
    }
}