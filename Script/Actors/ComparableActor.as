class AComparableActor : AActor {
    int opCmp(AComparableActor Other) const {
        return ActorNameOrLabel.opCmp(Other.ActorNameOrLabel);
    }
}

UFUNCTION()
mixin void SortComparableActors(TArray<AComparableActor>& Actors) {
    Actors.Sort();
}