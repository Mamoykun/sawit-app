package com.sawitku.repository;

import com.sawitku.entity.LahanPhoto;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface LahanPhotoRepository extends JpaRepository<LahanPhoto, Long> {

    List<LahanPhoto> findByLahanIdOrderByTakenAtDesc(Long lahanId);

    Optional<LahanPhoto> findByIdAndLahanId(Long id, Long lahanId);
}
