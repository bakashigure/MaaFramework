#pragma once

#include <filesystem>

#include "Base/UnitBase.h"
#include "ControlUnit/ControlUnitAPI.h"
#include "Utils/MessageNotifier.hpp"

MAA_CTRL_UNIT_NS_BEGIN

class ControlUnitMgr : public ControlUnitAPI
{
public:
    ControlUnitMgr(HWND hWnd, MaaControllerCallback callback, MaaCallbackTransparentArg callback_arg);
    virtual ~ControlUnitMgr() override = default;

public: // from ControlUnitAPI
    virtual bool find_device(/*out*/ std::vector<std::string>& devices) override;

    virtual bool connect() override;

    virtual bool request_uuid(/*out*/ std::string& uuid) override;
    virtual bool request_resolution(/*out*/ int& width, /*out*/ int& height) override;

    virtual bool start_app(const std::string& intent) override;
    virtual bool stop_app(const std::string& intent) override;

    virtual bool screencap(/*out*/ cv::Mat& image) override;

    virtual bool click(int x, int y) override;
    virtual bool swipe(int x1, int y1, int x2, int y2, int duration) override;

    virtual bool touch_down(int contact, int x, int y, int pressure) override;
    virtual bool touch_move(int contact, int x, int y, int pressure) override;
    virtual bool touch_up(int contact) override;

    virtual bool press_key(int key) override;
    virtual bool input_text(const std::string& text) override;

public:
    bool parse(const json::value& config);

    void set_touch_input_obj(std::shared_ptr<TouchInputBase> obj) { touch_input_ = std::move(obj); }
    void set_key_input_obj(std::shared_ptr<KeyInputBase> obj) { key_input_ = std::move(obj); }
    void set_screencap_obj(std::shared_ptr<ScreencapBase> obj) { screencap_ = std::move(obj); }

private:
    HWND hwnd_ = nullptr;

    MessageNotifier<MaaControllerCallback> notifier;

    std::shared_ptr<TouchInputBase> touch_input_ = nullptr;
    std::shared_ptr<KeyInputBase> key_input_ = nullptr;
    std::shared_ptr<ScreencapBase> screencap_ = nullptr;
};

MAA_CTRL_UNIT_NS_END
