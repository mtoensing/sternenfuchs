// Micro-benchmark: dispatch latency of RowWorkers::parallel_rows on the target.
// Build (from the repo root, inside the dev image):
//   g++ -O2 -std=c++20 -mcpu=cortex-a53 -I.work/starfox-enhanced/include \
//     scripts/rowworkers-latency.cpp .work/starfox-enhanced/src/render/row_workers.cpp -o rowworkers-latency -pthread
#include "starfox/render/row_workers.hpp"

#include <algorithm>
#include <atomic>
#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <thread>
#include <vector>

int main(int argc, char** argv) {
    const auto gap_us = argc > 1 ? std::atoi(argv[1]) : 0;   // idle gap between calls
    const auto work_iters = argc > 2 ? std::atoi(argv[2]) : 0; // busy work per row
    starfox::render::RowWorkers workers;
    workers.set_worker_count(0U);
    std::atomic<std::uint64_t> sink{0};
    std::vector<double> samples;
    for (int i = 0; i < 300; ++i) {
        if (gap_us > 0) std::this_thread::sleep_for(std::chrono::microseconds{gap_us});
        const auto begin = std::chrono::steady_clock::now();
        workers.parallel_rows(224U, [&](std::uint32_t first, std::uint32_t last) {
            std::uint64_t local = 0;
            for (auto row = first; row < last; ++row)
                for (int k = 0; k < work_iters; ++k) local += row * 31U + static_cast<unsigned>(k);
            sink += local;
        });
        const auto end = std::chrono::steady_clock::now();
        samples.push_back(std::chrono::duration<double, std::micro>(end - begin).count());
    }
    std::sort(samples.begin(), samples.end());
    std::printf("gap=%dus work=%d workers=%zu: median=%.0fus p95=%.0fus max=%.0fus (sink %llu)\n",
        gap_us, work_iters, workers.worker_count(), samples[samples.size() / 2],
        samples[samples.size() * 95 / 100], samples.back(),
        static_cast<unsigned long long>(sink.load()));
}
