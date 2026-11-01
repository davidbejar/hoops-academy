package com.hoopsacademy.core.application.port;

import com.hoopsacademy.core.application.shared.PageRequest;
import com.hoopsacademy.core.application.shared.PageResult;
import com.hoopsacademy.core.domain.approvals.ApprovalAction;
import com.hoopsacademy.core.domain.approvals.ApprovalRequest;
import com.hoopsacademy.core.domain.approvals.ApprovalRequestId;
import com.hoopsacademy.core.domain.approvals.ApprovalStatus;
import com.hoopsacademy.core.domain.membership.PersonId;
import com.hoopsacademy.core.domain.membership.PlayerId;
import java.util.Collection;
import java.util.Map;
import java.util.Optional;

/** Approval requests of the bound tenant. */
public interface ApprovalRepository {

    /** {@code requestedBy} present = only that person's requests (the COACH view). */
    record ApprovalFilter(Optional<ApprovalStatus> status, Optional<ApprovalAction> action, Optional<PlayerId> player,
            Optional<PersonId> requestedBy) {}

    /** @throws com.hoopsacademy.common.problem.ConflictException {@code APPROVAL_ALREADY_PENDING} */
    void insert(ApprovalRequest request);

    /**
     * Persists a decision; the row is version-checked against the state this transaction read.
     *
     * @throws com.hoopsacademy.common.problem.ConflictException {@code CONCURRENT_DECISION} when another decision won
     */
    void update(ApprovalRequest request);

    Optional<ApprovalRequest> find(ApprovalRequestId id);

    PageResult<ApprovalRequest> list(ApprovalFilter filter, PageRequest page);

    /** The requester of each player's ADD_PLAYER request (players without one are omitted). */
    Map<PlayerId, PersonId> addRequesters(Collection<PlayerId> players);

    long countPending();
}
