package com.hoopsacademy.common.testing;

import static com.hoopsacademy.common.testing.MembershipWorld.CHILD;
import static com.hoopsacademy.common.testing.MembershipWorld.CURRENT_TEAM;
import static com.hoopsacademy.common.testing.MembershipWorld.ENDED_TEAM;
import static com.hoopsacademy.common.testing.MembershipWorld.NEXT_SUMMER_TEAM;
import static com.hoopsacademy.common.testing.MembershipWorld.OWN_PLAYER;
import static com.hoopsacademy.common.testing.MembershipWorld.UNKNOWN_TEAM;
import static com.hoopsacademy.common.testing.MembershipWorld.member;
import static org.assertj.core.api.Assertions.assertThat;

import com.hoopsacademy.common.client.CoreMembership.TenantStatus;
import com.hoopsacademy.common.tenancy.AuthzContext;
import com.hoopsacademy.common.tenancy.TenantRole;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Stream;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.MethodSource;

/**
 * The rule that builds a caller's authorisation context from the membership tables (ADR-0066), as a table taken from
 * {@code docs/domain/authz-matrix.md} and ADR-0042: only an active person with the login in an ACTIVE tenant is a
 * member (anyone else gets 404); the own player counts with the PLAYER role, guardian links with PARENT; staff and
 * player teams are those whose season has not ended in the academy's zone; the known staff teams whose season ended
 * are the historic staff teams. A subclass runs the table against one implementation of the rule.
 */
public abstract class MembershipRuleContract {

    /** One row of the table: what the store holds and the context the caller gets (empty: not a member). */
    public record MembershipCase(String name, MembershipWorld world, Optional<AuthzContext> expected) {

        @Override
        public String toString() {
            return name;
        }
    }

    /** The implementation under test: the context of {@link MembershipWorld#SUBJECT} in the world's tenant. */
    protected abstract Optional<AuthzContext> resolve(MembershipWorld world);

    /** What the implementation must answer; an implementation that differs on a case says so here (ADR-0066). */
    protected Optional<AuthzContext> expected(MembershipCase row) {
        return row.expected();
    }

    @ParameterizedTest(name = "{0}")
    @MethodSource("com.hoopsacademy.common.testing.MembershipRuleContract#cases")
    void theContextFollowsTheMembershipRule(MembershipCase row) {
        assertThat(resolve(row.world())).isEqualTo(expected(row));
    }

    public static Stream<MembershipCase> cases() {
        return Stream.of(
                row("an ADMIN without relations is a member with the tenant's zone",
                        member(TenantRole.ADMIN), context(Set.of(TenantRole.ADMIN)).build()),
                notMember("a login without an active person in the tenant is no member", MembershipWorld.noMember()),
                notMember("a SUSPENDED tenant has no members",
                        member(TenantRole.ADMIN).tenant(TenantStatus.SUSPENDED)),
                notMember("a WITHDRAWN tenant has no members",
                        member(TenantRole.ADMIN).tenant(TenantStatus.WITHDRAWN)),
                notMember("a tenant the store does not know has no members", member(TenantRole.ADMIN).unknownTenant()),
                row("staff teams keep the seasons that end today in the academy's zone or later",
                        member(TenantRole.COACH).staffOf(CURRENT_TEAM, NEXT_SUMMER_TEAM),
                        context(Set.of(TenantRole.COACH)).staff(CURRENT_TEAM, NEXT_SUMMER_TEAM).build()),
                row("a staff team whose season ended yesterday in the academy's zone (today in UTC) is history",
                        member(TenantRole.COACH).staffOf(ENDED_TEAM, CURRENT_TEAM),
                        context(Set.of(TenantRole.COACH)).staff(CURRENT_TEAM).historic(ENDED_TEAM).build()),
                row(UNKNOWN_STAFF_TEAM,
                        member(TenantRole.COACH).staffOf(UNKNOWN_TEAM, CURRENT_TEAM),
                        context(Set.of(TenantRole.COACH)).staff(CURRENT_TEAM).build()),
                row("an ASSISTANT_COACH has current and historic staff teams like a COACH",
                        member(TenantRole.ASSISTANT_COACH).staffOf(CURRENT_TEAM, ENDED_TEAM),
                        context(Set.of(TenantRole.ASSISTANT_COACH)).staff(CURRENT_TEAM).historic(ENDED_TEAM).build()),
                row("staff rows are read whatever the roles (the context's checks ask for a staff role)",
                        member(TenantRole.PARENT).staffOf(CURRENT_TEAM, ENDED_TEAM),
                        context(Set.of(TenantRole.PARENT)).staff(CURRENT_TEAM).historic(ENDED_TEAM).build()),
                row("the own player counts with the PLAYER role; its ended team is no player team and no history",
                        member(TenantRole.PLAYER).ownPlayer(OWN_PLAYER, CURRENT_TEAM, ENDED_TEAM),
                        context(Set.of(TenantRole.PLAYER)).own(OWN_PLAYER).playerTeams(CURRENT_TEAM).build()),
                row("an own player record without the PLAYER role counts for nothing",
                        member(TenantRole.COACH).ownPlayer(OWN_PLAYER, CURRENT_TEAM),
                        context(Set.of(TenantRole.COACH)).build()),
                row("guardian links count with the PARENT role",
                        member(TenantRole.PARENT).guardianOf(CHILD, NEXT_SUMMER_TEAM),
                        context(Set.of(TenantRole.PARENT)).linked(CHILD).playerTeams(NEXT_SUMMER_TEAM).build()),
                row("guardian links without the PARENT role count for nothing",
                        member(TenantRole.ADMIN).guardianOf(CHILD, NEXT_SUMMER_TEAM),
                        context(Set.of(TenantRole.ADMIN)).build()),
                row("player teams are the current teams of the own and of the linked players",
                        member(TenantRole.PLAYER, TenantRole.PARENT).ownPlayer(OWN_PLAYER, CURRENT_TEAM)
                                .guardianOf(CHILD, NEXT_SUMMER_TEAM, ENDED_TEAM),
                        context(Set.of(TenantRole.PLAYER, TenantRole.PARENT)).own(OWN_PLAYER).linked(CHILD)
                                .playerTeams(CURRENT_TEAM, NEXT_SUMMER_TEAM).build()),
                row("a player's team the store does not know is no player team",
                        member(TenantRole.PLAYER).ownPlayer(OWN_PLAYER, UNKNOWN_TEAM, CURRENT_TEAM),
                        context(Set.of(TenantRole.PLAYER)).own(OWN_PLAYER).playerTeams(CURRENT_TEAM).build()),
                row("a former coach who is a parent keeps the history and the child's current team",
                        member(TenantRole.COACH, TenantRole.PARENT).staffOf(ENDED_TEAM)
                                .guardianOf(CHILD, ENDED_TEAM, CURRENT_TEAM),
                        context(Set.of(TenantRole.COACH, TenantRole.PARENT)).linked(CHILD).playerTeams(CURRENT_TEAM)
                                .historic(ENDED_TEAM).build()));
    }

    /** The name of the one case on which core's {@code MembershipLookup} differed (ADR-0066, difference 1). */
    public static final String UNKNOWN_STAFF_TEAM = "a staff row of a team the store does not know grants nothing";

    private static MembershipCase row(String name, MembershipWorld world, AuthzContext expected) {
        return new MembershipCase(name, world, Optional.of(expected));
    }

    private static MembershipCase notMember(String name, MembershipWorld world) {
        return new MembershipCase(name, world, Optional.empty());
    }

    /** An expected context of {@link MembershipWorld#PERSON} in the world's tenant, zone known. */
    public static ExpectedContext context(Set<TenantRole> roles) {
        return new ExpectedContext(roles);
    }

    /** Builds an expected context field by field; unset relations are empty. */
    public static final class ExpectedContext {

        private final Set<TenantRole> roles;
        private Set<UUID> staff = Set.of();
        private Set<UUID> linked = Set.of();
        private Optional<UUID> own = Optional.empty();
        private Set<UUID> playerTeams = Set.of();
        private Set<UUID> historic = Set.of();

        private ExpectedContext(Set<TenantRole> roles) {
            this.roles = roles;
        }

        public ExpectedContext staff(UUID... teams) {
            staff = Set.of(teams);
            return this;
        }

        public ExpectedContext linked(UUID... players) {
            linked = Set.of(players);
            return this;
        }

        public ExpectedContext own(UUID player) {
            own = Optional.of(player);
            return this;
        }

        public ExpectedContext playerTeams(UUID... teams) {
            playerTeams = Set.of(teams);
            return this;
        }

        public ExpectedContext historic(UUID... teams) {
            historic = Set.of(teams);
            return this;
        }

        public AuthzContext build() {
            return new AuthzContext(MembershipWorld.SUBJECT, MembershipWorld.PERSON, MembershipWorld.TENANT, roles,
                    staff, linked, own, playerTeams, Optional.of(MembershipWorld.ZONE), historic);
        }
    }
}
