#pragma once

#include <ostream>
#include <vector>

#include <onnxruntime/onnxruntime_cxx_api.h>

#include "Utils/JsonExt.hpp"
#include "VisionBase.h"
#include "VisionTypes.h"

MAA_VISION_NS_BEGIN

class NeuralNetworkClassifier : public VisionBase
{
public:
    struct Result
    {
        size_t cls_index = SIZE_MAX;
        std::string label;
        cv::Rect box {};
        double score = 0.0;
        std::vector<float> raw;
        std::vector<float> probs;

        MEO_JSONIZATION(cls_index, label, box, score, raw, probs);
    };
    using ResultsVec = std::vector<Result>;

public:
    void set_param(NeuralNetworkClassifierParam param) { param_ = std::move(param); }
    void set_session(std::shared_ptr<Ort::Session> session) { session_ = std::move(session); }
    ResultsVec analyze() const;

private:
    ResultsVec foreach_rois() const;
    Result classify(const cv::Rect& roi) const;
    void draw_result(const Result& res) const;

    void filter(ResultsVec& results, const std::vector<size_t>& expected) const;

    NeuralNetworkClassifierParam param_;
    std::shared_ptr<Ort::Session> session_ = nullptr;
};

MAA_VISION_NS_END
