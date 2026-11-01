package com.hoopsacademy.core.adapters.out.persistence;

import com.hoopsacademy.core.application.port.LogoRepository;
import com.hoopsacademy.core.domain.logo.ImageFormat;
import com.hoopsacademy.core.domain.logo.LogoImage;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.EntityManager;
import java.time.Instant;
import java.util.Arrays;
import java.util.Optional;

@ApplicationScoped
class JpaLogoRepository implements LogoRepository {

    private final EntityManager em;
    private final BoundTenant boundTenant;

    JpaLogoRepository(EntityManager em, BoundTenant boundTenant) {
        this.em = em;
        this.boundTenant = boundTenant;
    }

    @Override
    public Optional<StoredLogo> find() {
        return Optional.ofNullable(em.find(TenantLogoEntity.class, boundTenant.id()))
                .map(row -> new StoredLogo(LogoImage.restore(formatOf(row.contentType), row.bytes, row.etag),
                        row.updatedAt));
    }

    @Override
    public Optional<String> findEtag() {
        return em.createQuery("select l.etag from TenantLogoEntity l where l.id = :id", String.class)
                .setParameter("id", boundTenant.id())
                .getResultStream().findFirst();
    }

    @Override
    public StoredLogo save(LogoImage image, Instant now) {
        TenantLogoEntity row = em.find(TenantLogoEntity.class, boundTenant.id());
        boolean isNew = row == null;
        if (isNew) {
            row = new TenantLogoEntity();
            row.id = boundTenant.id();
        }
        row.contentType = image.format().mediaType();
        row.bytes = image.bytes();
        row.sizeBytes = image.sizeBytes();
        row.etag = image.etag();
        row.updatedAt = now;
        if (isNew) {
            em.persist(row);
        }
        return new StoredLogo(image, now);
    }

    @Override
    public boolean delete() {
        return em.createQuery("delete from TenantLogoEntity l where l.id = :id")
                .setParameter("id", boundTenant.id()).executeUpdate() > 0;
    }

    private static ImageFormat formatOf(String mediaType) {
        return Arrays.stream(ImageFormat.values()).filter(f -> f.mediaType().equals(mediaType)).findFirst()
                .orElseThrow(() -> new IllegalStateException("Unknown stored logo type " + mediaType));
    }
}
