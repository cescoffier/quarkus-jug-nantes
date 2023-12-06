package me.escoffier.demo;

import io.smallrye.common.annotation.RunOnVirtualThread;
import io.smallrye.reactive.messaging.MutinyEmitter;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.NotFoundException;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Emitter;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RunOnVirtualThread
public class MovieController {

    @Channel("movies")
    MutinyEmitter<Movie> emitter;

    @GetMapping("/movies")
    public List<Movie> getAll() {
        return Movie.listAll();
    }

    @PostMapping("/movies")
    @Transactional
    public Movie addMovie(Movie movie) {
        movie.persist();
        emitter.sendAndAwait(movie);
        return movie;
    }

    @DeleteMapping("/movies/{id}")
    @Transactional
    public void deleteMovie(Long id) {
        Movie movie = Movie.findById(id);
        if (movie != null) {
            movie.delete();
        } else {
            throw new NotFoundException("Movie not found");
        }
    }

}
