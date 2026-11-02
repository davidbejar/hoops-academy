package com.hoopsacademy.core.application.port;

import com.hoopsacademy.common.tenancy.TenantRole;
import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import com.hoopsacademy.core.domain.identity.UserId;
import com.hoopsacademy.core.domain.membership.Person;
import com.hoopsacademy.core.domain.membership.PersonId;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/** Members (person + roles) of the bound tenant. */
public interface PersonRepository {

    record MemberFilter(Optional<TenantRole> role, Optional<Boolean> active, Optional<String> query) {}

    void insert(Person person);

    void update(Person person);

    Optional<Person> find(PersonId id);

    List<Person> findAll(Collection<PersonId> ids);

    Optional<Person> findActiveByLogin(String subject);

    /** The member (active or not) with this e-mail, compared case-insensitively (unique per tenant). */
    Optional<Person> findByEmail(String email);

    boolean emailTaken(String email, Optional<PersonId> except);

    boolean loginLinked(UserId user);

    long countActiveAdmins();

    long countActive();

    /** Active members per tenant role (a member with several roles counts once per role). */
    Map<TenantRole, Long> countActiveByRole();

    PageResult<Person> list(MemberFilter filter, PageRequest page);
}
